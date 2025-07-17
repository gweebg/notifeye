defmodule NotifeyeWeb.AdminLive.AlertDescriptions.Index do
  @moduledoc false

  use NotifeyeWeb, :live_view

  alias Notifeye.AlertDescriptions

  @impl true
  def mount(_params, _session, socket) do
    alert_descriptions = AlertDescriptions.list_alert_descriptions()

    socket =
      socket
      |> stream(:alert_descriptions, alert_descriptions)

    {:ok, socket}
  end
end
