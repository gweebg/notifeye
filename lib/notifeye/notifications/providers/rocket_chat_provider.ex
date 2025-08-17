defmodule Notifeye.Notifications.Providers.RocketChat do
  @moduledoc """
  RocketChat notification provider.
  """

  @behaviour Notifeye.Notifications.Behaviour

  alias Notifeye.Accounts.User
  alias Notifeye.Accounts.Notifiers.RocketChat

  @contexts [:description_created, :assignment_created, :group_notification]
  @webhook_url System.get_env("ROCKET_CHAT_NOTIFICATION_HOOK")

  @impl true
  def send_notification(%User{} = user, context) do
    cond do
      is_nil(@webhook_url) ->
        {:skip, "#{provider_name()} provider is missing ROCKET_CHAT_NOTIFICATION_HOOK variable"}

      not can_notify?(user) ->
        {:skip, "#{provider_name()} is disabled for user #{user.email}"}

      true ->
        user.notification_preferences.rocket_chat.username
        |> RocketChat.new_body(context)
        |> RocketChat.deliver(url: @webhook_url)
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
