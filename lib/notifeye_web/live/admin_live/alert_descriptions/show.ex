defmodule NotifeyeWeb.AdminLive.AlertDescriptions.Show do
  @moduledoc false

  use NotifeyeWeb, :live_view

  alias Notifeye.AlertDescriptions
  alias Notifeye.AlertAssignments
  alias Notifeye.Monitoring

  # todo: review this code
  # todo: fix ui

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    case AlertDescriptions.get_alert_description(id, preload: [:user, :notification_group]) do
      nil ->
        socket =
          socket
          |> put_flash(:error, "Alert description not found")
          |> push_navigate(to: ~p"/admin/descriptions")

        {:noreply, socket}

      alert_description ->
        # Load related data
        alert_assignments = load_alert_assignments(id)
        alerts = load_related_alerts(id)

        socket =
          socket
          |> assign(:alert_description, alert_description)
          |> assign(:alert_assignments, alert_assignments)
          |> assign(:alerts, alerts)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_description", %{"id" => id}, socket) do
    case AlertDescriptions.get_alert_description(id) do
      nil ->
        socket =
          socket
          |> put_flash(:error, "Alert description not found")

        {:noreply, socket}

      alert_description ->
        case AlertDescriptions.delete_alert_description(alert_description) do
          {:ok, _deleted_description} ->
            socket =
              socket
              |> put_flash(:info, "Alert description deleted successfully")
              |> push_navigate(to: ~p"/admin/descriptions")

            {:noreply, socket}

          {:error, _changeset} ->
            socket =
              socket
              |> put_flash(:error, "Failed to delete alert description")

            {:noreply, socket}
        end
    end
  end

  # Helper functions to load related data
  defp load_alert_assignments(alert_description_id) do
    AlertAssignments.list_alert_assignments_for_alert_description(alert_description_id)
  end

  defp load_related_alerts(alert_description_id) do
    # Load alerts where the logz_id matches the alert_description.id
    try do
      alert = Monitoring.get_alert_for_description!(alert_description_id)
      [alert]
    rescue
      Ecto.NoResultsError -> []
    end
  end
end
