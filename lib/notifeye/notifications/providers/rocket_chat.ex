defmodule Notifeye.Notifications.Providers.RocketChat do
  @moduledoc """
  RocketChat notification provider.
  """

  @behaviour Notifeye.Notifications.Behaviour

  alias Notifeye.Accounts.User
  alias Notifeye.AlertDescriptions.AlertDescription

  @contexts [:description_created, :assignment_created, :group_notification]

  # todo: temporary, just for testing purposes
  @rocket_url "http://localhost:3000/hooks/6887c4bc81241c67cf8af394/kMuBogjncNqLgudbdpAfkNWdBPiHdBKCHQev3ouyEDLYWsK7"

  @impl true
  def send_notification(%User{} = user, context) do
    if can_notify?(user) do
      "gweebg"
      |> new_body(context)
      |> post_message(url: @rocket_url)
    else
      {:skip, "#{provider_name()} provider not configured or enabled"}
    end
  end

  # todo: use user's configs for rocket.chat
  @impl true
  def can_notify?(%User{email: _email}), do: true

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
