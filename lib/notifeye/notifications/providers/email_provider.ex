defmodule Notifeye.Notifications.Providers.Email do
  @moduledoc """
  Email notification provider.
  """

  @behaviour Notifeye.Notifications.Behaviour

  alias Notifeye.Accounts.User
  alias Notifeye.Accounts.Notifiers.Email

  alias Notifeye.Notifications.Message

  # todo: implement messaging for :lead_notification
  @contexts [:description_created, :assignment_created, :group_notification]

  @impl true
  def send_notification(%Message{} = message) do
    message.to
    |> Email.build_email(message.type, message.data)
    |> Email.deliver()
  end

  @impl true
  def can_notify?(%User{notification_preferences: notification_preferences}),
    do: notification_preferences.email.enabled

  @impl true
  def provider_name(), do: "email"

  @impl true
  def supported_contexts(), do: @contexts
end
