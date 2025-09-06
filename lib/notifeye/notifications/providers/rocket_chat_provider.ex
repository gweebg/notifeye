defmodule Notifeye.Notifications.Providers.RocketChat do
  @moduledoc """
  RocketChat notification provider.
  """

  @behaviour Notifeye.Notifications.Behaviour

  alias Notifeye.Accounts.User
  alias Notifeye.Accounts.Notifiers.RocketChat
  alias Notifeye.Notifications.Message

  @contexts [:description_created, :assignment_created, :group_notification]
  @webhook_url System.get_env("ROCKET_CHAT_NOTIFICATION_HOOK")

  @impl true
  def send_notification(%Message{to: %User{} = user} = message) do
    if @webhook_url != nil do
      user.notification_preferences.rocket_chat.username
      |> RocketChat.new_body(message.type, message.data)
      |> RocketChat.deliver(url: @webhook_url)
    else
      {:skip, "#{provider_name()} provider is missing ROCKET_CHAT_NOTIFICATION_HOOK variable"}
    end
  end

  @impl true
  def can_notify?(%User{notification_preferences: notification_preferences}),
    do: notification_preferences.rocket_chat.enabled

  @impl true
  def provider_name(), do: "rocket_chat"

  @impl true
  def supported_contexts(), do: @contexts
end
