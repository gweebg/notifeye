defmodule NotifeyeWeb.AlertLive.Index do
  use NotifeyeWeb, :live_view

  alias Notifeye.Monitoring
  alias NotifeyeWeb.Components.Cards

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Alerts
        <:actions>
          <.button variant="primary" navigate={~p"/alerts/new"}>
            <.icon name="hero-plus" /> New Alert
          </.button>
        </:actions>
      </.header>

      <%= for {alert_id, alert} <- @streams.alerts do %>
        <section>
          <.live_component module={Cards.AlertCard} id={alert_id} alert={alert} />
        </section>
      <% end %>

      <.table
        id="alerts"
        rows={@streams.alerts}
        row_click={fn {_id, alert} -> JS.navigate(~p"/alerts/#{alert}") end}
      >
        <:col :let={{_id, alert}} label="Logz">{alert.logz_id}</:col>
        <:col :let={{_id, alert}} label="Alert title">{alert.alert_title}</:col>
        <:col :let={{_id, alert}} label="Alert description">{alert.alert_description}</:col>
        <:col :let={{_id, alert}} label="Alert severity">{alert.alert_severity}</:col>
        <:col :let={{_id, alert}} label="Alert event samples">{alert.alert_event_samples}</:col>
        <:col :let={{_id, alert}} label="Alert tags">{alert.alert_tags}</:col>
        <:col :let={{_id, alert}} label="Start">{alert.start}</:col>
        <:col :let={{_id, alert}} label="End">{alert.end}</:col>
        <:action :let={{_id, alert}}>
          <div class="sr-only">
            <.link navigate={~p"/alerts/#{alert}"}>Show</.link>
          </div>
          <.link navigate={~p"/alerts/#{alert}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, alert}}>
          <.link
            phx-click={JS.push("delete", value: %{id: alert.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

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
