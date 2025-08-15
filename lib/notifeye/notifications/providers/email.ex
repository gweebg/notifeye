defmodule Notifeye.Notifications.Providers.Email do
  @moduledoc """
  Email notification provider.
  """

  @behaviour Notifeye.Notifications.Behaviour

  alias Notifeye.Accounts.User
  alias Notifeye.Accounts.UserNotifier

  alias Notifeye.Mailer

  @contexts [:description_created, :assignment_created, :group_notification, :lead_notification]

  @impl true
  def send_notification(%User{} = user, context) do
    if can_notify?(user) do
      user
      |> UserNotifier.build_email(for: context)
      |> Mailer.deliver()
    else
      {:skip, "#{provider_name()} is not configured for #{user.username}"}
    end
  end

  @impl true
  def can_notify?(%User{notification_preferences: notification_preferences}),
    do: notification_preferences.email.enabled

  @impl true
  def provider_name(), do: "email"

  @impl true
  def supported_contexts(), do: @contexts
end
