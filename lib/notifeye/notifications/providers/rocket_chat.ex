defmodule Notifeye.Notifications.Providers.RocketChat do
  @moduledoc """
  RocketChat notification provider.
  """

  @behaviour Notifeye.Notifications.Behaviour

  alias Notifeye.Accounts.User
  alias Notifeye.AlertDescriptions.AlertDescription

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
        |> new_body(context)
        |> post_message(url: @webhook_url)
    end
  end

  @impl true
  def can_notify?(%User{notification_preferences: notification_preferences}),
    do: notification_preferences.rocket_chat.enabled

  @impl true
  def provider_name(), do: "rocket_chat"

  @impl true
  def supported_contexts(), do: @contexts

  defp post_message(content, url: webhook_url) do
    case Req.post(webhook_url,
           json: content,
           headers: [{"Content-Type", "application/json"}]
         ) do
      {:ok, %Req.Response{status: 200} = response} ->
        {:ok, response.body}

      {:ok, %Req.Response{status: status}} ->
        {:error, status}

      {:error, exception} ->
        {:error, exception}
    end
  end

  defp new_body(username, {:description_created, %AlertDescription{} = desc}) do
    url = NotifeyeWeb.Endpoint.url() <> "/admin/descriptions/#{desc.id}/edit"

    %{
      channel: "@#{username}",
      attachments: [
        %{
          title: "New Alert Identified",
          text: "A new alert type has been identified by *Notifeye*. This led to the creation
            of the [Alert Description #{desc.id}](#{url}) that requires further configuration
            so that future alerts of this type can be processed accordingly.",
          color: "#764FA5",
          actions: [
            %{
              type: "button",
              text: "Open in Browser",
              url: url,
              buttonType: "primary"
            }
          ]
        }
      ]
    }
  end

  defp new_body(username, _context) do
    %{
      channel: "@#{username}",
      text: username
    }
  end
end
