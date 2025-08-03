defmodule NotifeyeWeb.AdminLive.AlertDescriptions.Show do
  @moduledoc false

  use NotifeyeWeb, :live_view

  alias Notifeye.AlertDescriptions
  alias Notifeye.AlertAssignments
  alias Notifeye.Monitoring

  use NotifeyeWeb.Components

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    case AlertDescriptions.get_alert_description(id) do
      nil ->
        {:noreply, handle_not_found(socket)}

      alert_description ->
        socket =
          socket
          |> assign(:alert_description, alert_description)
          |> load_related_data(id)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_description", %{"id" => id}, socket) do
    with {:ok, alert_description} <- fetch_alert_description(id),
         {:ok, _deleted} <- AlertDescriptions.delete_alert_description(alert_description) do
      {:noreply, handle_successful_deletion(socket)}
    else
      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Alert description not found")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete alert description")}
    end
  end

  defp handle_not_found(socket) do
    socket
    |> put_flash(:error, "Alert description not found")
    |> push_navigate(to: ~p"/admin/descriptions")
  end

  defp load_related_data(socket, description_id) do
    alert_assignments = AlertAssignments.list_assignments_since(description_id)
    total_assignments = AlertAssignments.total_count(for: description_id)
    alerts = Monitoring.list_alerts_since(description_id)
    total_alerts = Monitoring.total_count(for: description_id)

    socket
    |> assign(:alert_assignments, alert_assignments)
    |> assign(:total_assignments, total_assignments)
    |> assign(:alerts, alerts)
    |> assign(:total_alerts, total_alerts)
  end

  defp fetch_alert_description(id) do
    case AlertDescriptions.get_alert_description(id) do
      nil -> {:error, :not_found}
      alert_description -> {:ok, alert_description}
    end
  end

  defp handle_successful_deletion(socket) do
    socket
    |> put_flash(:info, "Alert description deleted successfully")
    |> push_navigate(to: ~p"/admin/descriptions")
  end

  defp assignment_indicator_class(:open), do: "bg-info"
  defp assignment_indicator_class(:closed), do: "bg-success"
  defp assignment_indicator_class(_), do: "bg-warning"
end
