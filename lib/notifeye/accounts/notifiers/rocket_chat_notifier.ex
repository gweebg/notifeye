defmodule Notifeye.Accounts.Notifiers.RocketChat do
  @moduledoc false

  require Logger

  def deliver(content, url: webhook_url) do
    Logger.metadata(to: Map.get(content, :channel, "-"), webhook_url: webhook_url)

    case Req.post(webhook_url,
           json: content,
           headers: [{"Content-Type", "application/json"}]
         ) do
      {:ok, %Req.Response{status: 200} = response} ->
        Logger.debug("RocketChat notification sent successfully")
        {:ok, response.body}

      {:ok, %Req.Response{status: status} = response} ->
        Logger.error("RocketChat notification failed with status: #{status}",
          status: status,
          error: response.body
        )

        {:error, status}

      {:error, exception} ->
        Logger.error("RocketChat notification failed with exception",
          error: inspect(exception)
        )

        {:error, exception}
    end
  end

  defp url(), do: NotifeyeWeb.Endpoint.url()

  def new_body(username, :group_notification, %{group: g, assignment: a}) do
    desc_url = "#{url()}/descriptions/#{a.alert_description_id}"
    assignment_url = "#{url()}/assignments/acknowledge/#{a.id}"

    %{
      channel: "@#{username}",
      attachments: [
        %{
          title: "(#{g.name}) A new alert has been assigned!",
          text: "A new alert of type [#{a.alert_description_id}](#{desc_url}), of
                 *#{a.alert.alert_severity}* severity has been assigned to the user
                 #{a.user.username}. See more details by pressing the button bellow.
                 \nYou're receiving this notification because you are part of the
                 notification group #{g.name} which is enabled for the alert
                 description #{a.alert_description_id}.",
          color: "#0096FF",
          actions: [
            %{
              type: "button",
              text: "Open in Browser",
              url: assignment_url,
              buttonType: "primary"
            }
          ]
        }
      ]
    }
  end

  def new_body(username, :assignment_created, %{assignment: a}) do
    url = "#{url()}/assignments/acknowledge/#{a.id}"

    %{
      channel: "@#{username}",
      attachments: [
        %{
          title: "Gotcha!",
          text: "*Notifeye* has processed an alert that was triggered
                 by some action performed by your account. Please, carefully
                 review and acknowledge the assignment by pressing the button bellow.
                 \n*You have 24 hours to acknowledge this event.*",
          color: "#ff3333",
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

  def new_body(username, :description_created, %{description: d}) do
    url = "#{url()}/descriptions/#{d.id}/edit"

    %{
      channel: "@#{username}",
      attachments: [
        %{
          title: "New Alert Identified!",
          text: "A new alert type has been identified by *Notifeye*. This led to the creation
            of the [Alert Description #{d.id}](#{url}) that requires further configuration
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

  def new_body(username, type, data) do
    %{
      channel: "@#{username}",
      text: "#{inspect(type)}: #{inspect(data)}"
    }
  end
end
