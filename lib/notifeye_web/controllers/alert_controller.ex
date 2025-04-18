defmodule NotifeyeWeb.AlertController do
  use NotifeyeWeb, :controller

  alias Notifeye.Alerts
  alias Notifeye.Alerts.Alert

  action_fallback NotifeyeWeb.FallbackController

  def create(conn, %{"alert" => alert_params}) do
    with {:ok, %Alert{} = alert} <- Alerts.create_alert(alert_params) do
      conn
      |> put_status(:created)
      |> render(:show, alert: alert)
    end
  end
end
