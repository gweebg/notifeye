defmodule Notifeye.Notifications.ProviderSelector do
  @moduledoc """
  Handles selection of notification providers based on user capabilities,
  context type, and active rules.
  """

  alias Notifeye.Accounts.User
  alias Notifeye.Notifications.Providers.{Email, RocketChat}
  alias Notifeye.Rules
  alias Notifeye.AlertAssignments.AlertAssignment
  alias Notifeye.AlertDescriptions.AlertDescription.Rule

  @providers [Email, RocketChat]
  @rule_applicable_contexts [:assignment_created, :lead_notification, :group_notification]

  def select(%User{} = user, context) do
    context_type = context_type(context)

    if context_type in @rule_applicable_contexts do
      rule_based_providers(user, context, context_type)
    else
      default_providers(user, context_type)
    end
  end

  def available_providers do
    Enum.map(@providers, & &1.provider_name())
  end

  defp rule_based_providers(user, context, context_type) do
    with {desc, alert} <- extract_rule_data(context),
         %Rule{} = rule <- Rules.get_active_rule(desc.id),
         true <- Rules.check(desc.id, alert),
         providers when providers != [] <- parse_rule_providers(rule.action_value) do
      filter_providers(user, context_type, providers)
    else
      _ ->
        default_providers(user, context_type)
    end
  end

  defp default_providers(user, context_type) do
    filter_providers(user, context_type)
  end

  defp filter_providers(user, context_type, allowed_names \\ nil) do
    Enum.filter(@providers, fn provider ->
      name_ok = is_nil(allowed_names) or provider.provider_name() in allowed_names
      name_ok and can_use?(provider, user, context_type)
    end)
  end

  defp can_use?(provider, user, context_type) do
    provider.can_notify?(user) and context_type in provider.supported_contexts()
  end

  defp parse_rule_providers(nil), do: []
  defp parse_rule_providers(""), do: []

  defp parse_rule_providers(str) do
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp context_type(context) when is_tuple(context), do: elem(context, 0)

  defp extract_rule_data({type, %AlertAssignment{alert_description: desc, alert: alert}})
       when not is_nil(desc) and type in [:assignment_created, :lead_notification],
       do: {desc, alert}

  defp extract_rule_data(
         {:group_notification, _group, %AlertAssignment{alert_description: desc, alert: alert}}
       )
       when not is_nil(desc),
       do: {desc, alert}

  defp extract_rule_data(_), do: nil
end
