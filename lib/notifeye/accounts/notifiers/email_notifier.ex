defmodule Notifeye.Accounts.Notifiers.Email do
  @moduledoc false

  import Swoosh.Email

  require Logger

  alias Notifeye.Mailer
  alias Notifeye.Accounts.User

  use Phoenix.Swoosh, view: NotifeyeWeb.EmailView

  def deliver(email) do
    # this is process-wide, but since I only call
    # the deliver function within oban jobs it's fine
    Logger.metadata(to: email.to, subject: email.subject)

    case Mailer.deliver(email) do
      {:ok, metadata} ->
        Logger.debug("email delivered successfully",
          message_id: Map.get(metadata, :id)
        )

        {:ok, metadata}

      {:error, reason} ->
        Logger.error("failed to deliver email",
          error: inspect(reason)
        )

        {:error, reason}
    end
  end

  defp url(), do: NotifeyeWeb.Endpoint.url()

  # new description
  def build_email(%User{} = user, :description_created, %{description: d}) do
    desc_url = "#{url()}/descriptions/#{d.id}"

    base_email(to: user)
    |> subject("(##{d.id}) A new alert type has been identified")
    |> assign(:user, user)
    |> assign(:description, d)
    |> assign(:description_url, desc_url)
    |> render_body("description_created.html")
  end

  # new assignment
  def build_email(%User{} = user, :assignment_created, %{assignment: a}) do
    user_url = "#{url()}/users/settings"
    assignment_url = "#{url()}/assignments/acknowledge/#{a.id}"

    base_email(to: user)
    |> subject("You've been assigned to a new alert")
    |> assign(:user, user)
    |> assign(:assignment, a)
    |> assign(:user_url, user_url)
    |> assign(:assignment_url, assignment_url)
    |> render_body("assignment_created.html")
  end

  # group notification
  def build_email(%User{} = user, :group_notification, %{group: g, assignment: a}) do
    desc_url = "#{url()}/descriptions/#{a.alert_description_id}"
    url = "#{url()}/assignments/acknowledge/#{a.id}"

    base_email(to: user)
    |> subject("(##{a.alert_description_id}) Group notification")
    |> assign(:user, user)
    |> assign(:notification_group, g)
    |> assign(:assignment, a)
    |> assign(:desc_url, desc_url)
    |> assign(:url, url)
    |> render_body("group_notification.html")
  end

  # lead notification
  # todo: build_email

  def build_email(%User{} = user, type, data) do
    base_email(to: user)
    |> subject(inspect(type))
    |> text_body(inspect(data))
  end

  defp base_email(to: %User{} = user) do
    new()
    |> to(user.notification_preferences.email.email_address)
    |> from({"Notifeye", "notifications@notifeye.com"})
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
