defmodule Notifeye.Notifications.RuleEngine do
  @moduledoc """
  Dynamically applies rules of associated alerts to notification
  messages, reducing their provider sets.
  """

  alias Notifeye.Notifications.Message

  alias Notifeye.Rules
  alias Notifeye.AlertAssignments.AlertAssignment
  alias Notifeye.AlertDescriptions.AlertDescription.Rule

  alias Notifeye.Accounts.User

  @doc """
  Returns a `%Message{}` with is `providers` field filtered based on
  existing rules (`%Rule{}`) and user preferences (`%User{}`).

  Rules are only applied if the `%Message{}` contains `rule: true` in its
  metadata field.
  """
  def apply(%Message{metadata: %{rule: true}} = message) do
    with %AlertAssignment{} = a <- get_assignment(message),
         %Rule{} = rule <- Rules.get_active_rule(a.alert_description_id),
         true <- Rules.check(rule, a.alert) do
      %Message{
        message
        | providers:
            message
            |> filter_with_rule(rule)
            |> filter_with_user()
      }
    else
      _other -> message
    end
  end

  def apply(%Message{} = message), do: message

  defp get_assignment(%Message{data: %{assignment: %AlertAssignment{} = a}}), do: a
  defp get_assignment(_), do: nil

  defp filter_with_rule(_m, %Rule{action: :nothing}), do: []
  defp filter_with_rule(_m, %Rule{action_value: nil}), do: []
  defp filter_with_rule(_m, %Rule{action_value: ""}), do: []

  defp filter_with_rule(%Message{providers: providers}, %Rule{action_value: action_value}) do
    rule_providers =
      action_value
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.downcase/1)
      |> Enum.reduce(&(&1 == ""))

    providers
    |> Enum.filter(fn p -> p.provider_name() in rule_providers end)
  end

  defp filter_with_user(%Message{type: t, to: %User{} = rcpt, providers: providers}) do
    providers
    |> Enum.filter(fn provider ->
      provider.can_notify?(rcpt) and t in provider.supported_contexts()
    end)
  end
end
