defmodule Notifeye.Accounts.UserNotifier do
  @moduledoc false

  import Swoosh.Email

  alias Notifeye.Mailer
  alias Notifeye.Accounts.User
  alias Notifeye.AlertAssignments.AlertAssignment
  alias Notifeye.AlertDescriptions.AlertDescription
  alias Notifeye.Notifications.NotificationGroup

  use Phoenix.Swoosh, view: NotifeyeWeb.EmailView

  defp base_email(to: %User{} = user) do
    new()
    |> to(user.notification_preferences.email.email_address)
    |> from({"Notifeye", "noreply@notifeye.com"})
  end

  def build_email(
        %User{} = user,
        for: {:assignment_created, %AlertAssignment{} = assignment}
      ) do
    base_url = NotifeyeWeb.Endpoint.url()
    user_url = base_url <> "/users/settings"
    assignment_url = base_url <> "/assignments/#{assignment.id}/acknowledge"

    base_email(to: user)
    |> subject("You've been assigned to a new alert")
    |> assign(:user, user)
    |> assign(:assignment, assignment)
    |> assign(:user_url, user_url)
    |> assign(:assignment_url, assignment_url)
    |> render_body("assignment_created.html")
  end

  def build_email(
        %User{} = user,
        for: {:description_created, %AlertDescription{} = description}
      ) do
    description_url =
      NotifeyeWeb.Endpoint.url() <>
        "/admin/descriptions/#{description.id}"

    base_email(to: user)
    |> subject("(##{description.id}) A new alert type has been identified")
    |> assign(:user, user)
    |> assign(:description, description)
    |> assign(:description_url, description_url)
    |> render_body("description_created.html")
  end

  def build_email(
        %User{} = user,
        for: {:group_notification, %NotificationGroup{} = ng, %AlertAssignment{} = as}
      ) do
    alert_url =
      NotifeyeWeb.Endpoint.url() <>
        "/alerts/#{as.alert_id}"

    base_email(to: user)
    |> subject("(##{as.alert_description_id}) Group notification")
    |> assign(:user, user)
    |> assign(:notification_group, ng)
    |> assign(:assignment, as)
    |> assign(:alert_url, alert_url)
    |> render_body("group_notification.html")
  end

  def build_email(%User{} = user, for: _) do
    base_email(to: user)
  end

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Notifeye", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Log in instructions", """

    ==============================

    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end
end
