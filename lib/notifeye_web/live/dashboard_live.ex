defmodule NotifeyeWeb.DashboardLive do
  @moduledoc """
  Real-time dashboard for monitoring alerts, assignments, and notifications.
  Admin-only access with configurable time windows and refresh intervals.
  """

  use NotifeyeWeb, :live_view

  alias Notifeye.Dashboard

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:refresh_interval, 120)
      |> assign(:time_window, :week)
      |> assign(:alert_stats, %{})
      |> assign(:assignment_stats, %{})
      |> assign(:notification_stats, %{})
      |> assign(:loading, true)

    # load_all_stats(socket)

    if connected?(socket) do
      Dashboard.subscribe_dashboard_updates()
      send(self(), :load_dashboard_data)
      schedule_refresh(socket.assigns.refresh_interval)
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(:load_dashboard_data, socket) do
    socket = load_all_stats(socket)
    {:noreply, assign(socket, :loading, false)}
  end

  @impl true
  def handle_info(:refresh_data, socket) do
    socket = load_all_stats(socket)
    schedule_refresh(socket.assigns.refresh_interval)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:created, _alert}, socket) do
    # Handle real-time alert creation
    socket = load_alert_stats(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:updated, _alert}, socket) do
    # Handle real-time alert updates
    socket = load_alert_stats(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_description, _alert_description}, socket) do
    # Handle alert description changes that might affect dashboard
    socket = load_alert_stats(socket)
    {:noreply, socket}
  end

  # Handle other PubSub messages
  @impl true
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  def handle_event("navigate_alert", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/alerts/#{id}")}
  end

  @impl true
  def handle_event("change_time_window", %{"time_window" => time_window}, socket) do
    time_window = String.to_existing_atom(time_window)

    socket =
      socket
      |> assign(:time_window, time_window)
      |> load_all_stats()

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_refresh_interval", %{"interval" => interval}, socket) do
    interval = String.to_integer(interval)

    socket = assign(socket, :refresh_interval, interval)

    # Reschedule with new interval
    schedule_refresh(interval)

    {:noreply, socket}
  end

  # Private functions

  defp load_all_stats(socket) do
    socket
    |> load_alert_stats()
    |> load_assignment_stats()
    |> load_notification_stats()
  end

  defp load_alert_stats(socket) do
    case Dashboard.get_alert_stats(socket.assigns.time_window) do
      {:ok, stats} -> assign(socket, :alert_stats, stats)
      {:error, _reason} -> assign(socket, :alert_stats, %{})
    end
  end

  defp load_assignment_stats(socket) do
    case Dashboard.get_assignment_stats(socket.assigns.time_window) do
      {:ok, stats} -> assign(socket, :assignment_stats, stats)
      {:error, _reason} -> assign(socket, :assignment_stats, %{})
    end
  end

  defp load_notification_stats(socket) do
    case Dashboard.get_notification_stats(socket.assigns.time_window) do
      {:ok, stats} -> assign(socket, :notification_stats, stats)
      {:error, _reason} -> assign(socket, :notification_stats, %{})
    end
  end

  defp schedule_refresh(interval_seconds) do
    Process.send_after(self(), :refresh_data, interval_seconds * 1000)
  end

  # Helper functions for the template

  def get_stat(stats, key, default \\ 0) do
    Map.get(stats, key, default)
  end

  defp format_time_window(:day), do: "Last 24 hours"
  defp format_time_window(:week), do: "Last 7 days"
  defp format_time_window(:month), do: "Last 30 days"

  # defp format_severity(severity) do
  #   severity
  #   |> to_string()
  #   |> String.capitalize()
  # end

  # defp format_status(status) do
  #   status
  #   |> to_string()
  #   |> String.capitalize()
  # end

  # defp severity_badge_class("high"), do: "badge-error"
  # defp severity_badge_class("medium"), do: "badge-warning"
  # defp severity_badge_class("low"), do: "badge-info"
  # defp severity_badge_class(_), do: "badge-neutral"

  # defp status_badge_class(:open), do: "badge-warning"
  # defp status_badge_class(:closed), do: "badge-success"
  # defp status_badge_class(:unassigned), do: "badge-info"
  # defp status_badge_class(:expired), do: "badge-error"
  # defp status_badge_class(_), do: "badge-neutral"
end
