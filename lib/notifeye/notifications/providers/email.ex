defmodule Notifeye.Notifications.Providers.Email do
  @moduledoc """
  Email notification provider.
  """

  @behaviour Notifeye.Notifications.Behaviour

  alias Notifeye.Accounts.User
  alias Notifeye.Accounts.UserNotifier

  alias Notifeye.Mailer

  @contexts [:description_created, :assignment_created, :group_notification]

  @impl true
  def send_notification(%User{} = user, context) do
    if can_notify?(user) do
      user
      |> UserNotifier.build_email(for: context)
      |> Mailer.deliver()
    else
      {:skip, "email is not configured for #{user.username}"}
    end
  end

  # todo: later on, update this function to fetch data from the
  # todo: user's preferences, i.e. if it has emails disabled
  @impl true
  def can_notify?(%User{email: email}) when is_binary(email) and email != "", do: true
  def can_notify?(_user), do: false

  @impl true
  def provider_name(), do: "email"

  @impl true
  def supported_contexts(), do: @contexts
end
