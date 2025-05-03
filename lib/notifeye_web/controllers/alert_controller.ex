defmodule NotifeyeWeb.AlertController do
  use NotifeyeWeb, :controller

  alias Notifeye.Monitoring
  alias Notifeye.Monitoring.Alert

  action_fallback NotifeyeWeb.FallbackController

  def create(conn, %{"alert" => alert_params}) do
    with {:ok, %Alert{} = alert} <-
           Monitoring.create_alert(conn.assigns.current_scope, alert_params) do
      conn
      |> put_status(:created)
      |> json(alert)
    end
  end
end
