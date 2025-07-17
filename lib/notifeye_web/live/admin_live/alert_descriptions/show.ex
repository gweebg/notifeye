defmodule NotifeyeWeb.AdminLive.AlertDescriptions.Show do
  @moduledoc false

  use NotifeyeWeb, :live_view

  alias Notifeye.AlertDescriptions

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    case AlertDescriptions.get_alert_description(id) do
      nil ->
        socket =
          socket
          |> put_flash(:error, "Alert description not found")
          |> push_navigate(to: ~p"/admin/alert-descriptions")

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

  # Helper functions to load related data
  defp load_alert_assignments(_alert_description_id) do
    # This would need to be implemented based on your AlertAssignments context
    # For now, returning empty list as a placeholder
    []
  end

  defp load_related_alerts(_alert_description_id) do
    # This would load alerts where the logz_id matches the alert_description.id
    # or any other relationship you have between alerts and alert descriptions
    # For now, returning empty list as a placeholder
    []
  end
end
