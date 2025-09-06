defmodule Notifeye.Notifications.Dispatcher do
  @moduledoc """
  Handles the dispatch of notifications to users through configured providers.

  This module is responsible for selecting the appropriate notification providers
  based on user capabilities and the type of notification context, and then sending
  the notification through each applicable provider.
  """

  alias Notifeye.Notifications.Message

  @doc """
  Given a message, uses the `%Message{}`'s own providers to send notifications.

  After execution, returns a map containing the provider name as the keys with,
  the corresponding result from sending the notification as the value.

  ## Examples

      iex> notify(%Message{providers: [Email, RocketChat]})
      %Message{results: %{email: result, rocket_chat: result}}
  """
  def notify(%Message{} = message) do
    results =
      message.providers
      |> Enum.map(fn provider ->
        result = provider.send_notification(message)
        {provider.provider_name(), result}
      end)
      |> Enum.into(%{})

    %Message{message | results: results}
  end
end
