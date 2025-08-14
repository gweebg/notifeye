defmodule Notifeye.Notifications.Dispatcher do
  @moduledoc """
  Handles the dispatch of notifications to users through configured providers.

  This module is responsible for selecting the appropriate notification providers
  based on user capabilities and the type of notification context, and then sending
  the notification through each applicable provider.
  """

  alias Notifeye.Accounts.User
  alias Notifeye.Notifications.ProviderSelector

  def notify(%User{} = user, context) do
    applicable_providers = ProviderSelector.select(user, context)

    results =
      applicable_providers
      |> Enum.map(fn provider ->
        result = provider.send_notification(user, context)
        {provider.provider_name(), result}
      end)
      |> Enum.into(%{})

    {:ok, results}
  end

  def available_providers do
    ProviderSelector.available_providers()
  end
end
