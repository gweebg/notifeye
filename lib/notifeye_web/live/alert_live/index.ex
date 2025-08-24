defmodule NotifeyeWeb.AlertLive.Index do
  use NotifeyeWeb, :live_view

  alias Notifeye.Monitoring
  alias NotifeyeWeb.Components.Cards

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Monitoring.subscribe_alerts(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Alerts")
     |> stream(:alerts, Monitoring.list_alerts(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    alert = Monitoring.get_alert!(socket.assigns.current_scope, id)
    {:ok, _} = Monitoring.delete_alert(socket.assigns.current_scope, alert)

    {:noreply, stream_delete(socket, :alerts, alert)}
  end

  @impl true
  def handle_info({type, %Notifeye.Monitoring.Alert{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(socket, :alerts, Monitoring.list_alerts(socket.assigns.current_scope), reset: true)}
  end
end
