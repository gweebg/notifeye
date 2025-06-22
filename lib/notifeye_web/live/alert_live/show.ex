defmodule NotifeyeWeb.AlertLive.Show do
  use NotifeyeWeb, :live_view

  alias Notifeye.Monitoring

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Alert {@alert.id}
        <:subtitle>This is a alert record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/alerts"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/alerts/#{@alert}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit alert
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Logz">{@alert.logz_id}</:item>
        <:item title="Alert title">{@alert.alert_title}</:item>
        <:item title="Alert description">{@alert.alert_description}</:item>
        <:item title="Alert severity">{@alert.alert_severity}</:item>
        <:item title="Alert event samples">{@alert.alert_event_samples}</:item>
        <:item title="Alert tags">{@alert.alert_tags}</:item>
        <:item title="Start">{@alert.start}</:item>
        <:item title="End">{@alert.end}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Monitoring.subscribe_alerts(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Alert")
     |> assign(:alert, Monitoring.get_alert!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %Notifeye.Monitoring.Alert{id: id} = alert},
        %{assigns: %{alert: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :alert, alert)}
  end

  def handle_info(
        {:deleted, %Notifeye.Monitoring.Alert{id: id}},
        %{assigns: %{alert: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current alert was deleted.")
     |> push_navigate(to: ~p"/alerts")}
  end

  def handle_info({type, %Notifeye.Monitoring.Alert{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
