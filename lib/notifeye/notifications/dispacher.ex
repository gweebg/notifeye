defmodule Notifeye.Notifications.Dispacher do
  @moduledoc """
  Handles the dispatch of notifications to users through configured providers.

  This module is responsible for selecting the appropriate notification providers
  based on user capabilities and the type of notification context, and then sending
  the notification through each applicable provider.
  """

  alias Notifeye.Accounts.User
  alias Notifeye.Notifications.Providers.Email

  @providers [Email]

  def notify(%User{} = user, context) do
    applicable_providers = get_applicable_providers(user, context)

    results =
      applicable_providers
      |> Enum.map(fn provider ->
        result = provider.send_notification(user, context)
        {provider.provider_name(), result}
      end)
      |> Enum.into(%{})

    {:ok, results}
  end

  defp get_applicable_providers(%User{} = user, context) do
    context_type = get_context_type(context)

    @providers
    |> Enum.filter(fn provider ->
      provider_handles?(provider, user, context_type)
    end)
  end

  defp provider_handles?(provider, user, context_type) do
    # check is user can be notified via this provider
    # or if the provider supports this message type
    provider.can_notify?(user) and
      context_type in provider.supported_contexts()
  end

  # the message type is always the first element of the tuple
  defp get_context_type(context) when is_tuple(context), do: elem(context, 0)

  def available_providers, do: @providers
end
