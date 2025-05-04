defmodule NotifeyeWeb.AlertController do
  use NotifeyeWeb, :controller

  alias Notifeye.Monitoring
  alias Notifeye.Monitoring.Alert
  alias NotifeyeWeb.AlertJSON

  require Logger

  action_fallback NotifeyeWeb.FallbackController

  def create(conn, %{"alert" => alert_params}) do
    # temporary logging for alert discovery
    Logger.debug("alert: #{inspect(alert_params)}", request_logger: true)

    with {:ok, %Alert{} = alert} <-
           Monitoring.create_alert(conn.assigns.current_scope, alert_params) do
      conn
      |> put_status(:created)
      |> json(AlertJSON.show(%{alert: alert}))
    end
  end
end
