defmodule Notifeye.Accounts.Notifiers.RocketChat do
  @moduledoc false

  require Logger

  alias Notifeye.AlertDescriptions.AlertDescription
  alias Notifeye.AlertAssignments.AlertAssignment
  alias Notifeye.AlertDescriptions.AlertDescription
  alias Notifeye.Notifications.NotificationGroup

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

  def new_body(
        username,
        {:group_notification, %NotificationGroup{} = ng, %AlertAssignment{} = as}
      ) do
    base_url = NotifeyeWeb.Endpoint.url()
    desc_url = base_url <> "/admin/descriptions/#{as.alert_description_id}"
    url = base_url <> "/assignments/#{as.id}/acknowledge"

    %{
      channel: "@#{username}",
      attachments: [
        %{
          title: "(#{ng.name}) A new alert has been assigned!",
          text: "A new alert of type [#{as.alert_description_id}](#{desc_url}), of
                 *#{as.alert.alert_severity}* severity has been assigned to the user
                 #{as.user.username}. See more details by pressing the button bellow.
                 \nYou're receiving this notification because you are part of the
                 notification group #{ng.name} which is enabled for the alert
                 description #{as.alert_description_id}.",
          color: "#0096FF",
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

  def new_body(username, {:assignment_created, %AlertAssignment{} = assignment}) do
    url = NotifeyeWeb.Endpoint.url() <> "/assignments/#{assignment.id}/acknowledge"

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

  def new_body(username, {:description_created, %AlertDescription{} = desc}) do
    url = NotifeyeWeb.Endpoint.url() <> "/admin/descriptions/#{desc.id}/edit"

    %{
      channel: "@#{username}",
      attachments: [
        %{
          title: "New Alert Identified!",
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

  def new_body(username, _context) do
    %{
      channel: "@#{username}",
      text: username
    }
  end
end
