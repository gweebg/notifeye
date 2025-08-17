defmodule Notifeye.Notifications.Providers.Email do
  @moduledoc """
  Email notification provider.
  """

  @behaviour Notifeye.Notifications.Behaviour

  alias Notifeye.Accounts.User
  alias Notifeye.Accounts.Notifiers.Email

  # , :lead_notification]
  @contexts [:description_created, :assignment_created, :group_notification]

  @impl true
  def send_notification(%User{} = user, context) do
    if can_notify?(user) do
      user
      |> Email.build_email(for: context)
      |> Email.deliver()
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
