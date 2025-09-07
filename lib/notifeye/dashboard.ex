defmodule Notifeye.Dashboard do
  @moduledoc """
  Dashboard context for real-time monitoring and statistics.

  Provides aggregated data and metrics for alerts, assignments, and notifications
  with configurable time windows and real-time updates via PubSub.
  """

  import Ecto.Query, warn: false
  alias Notifeye.Repo

  alias Notifeye.Monitoring.Alert
  alias Notifeye.AlertAssignments.AlertAssignment

  @type time_window :: :day | :week | :month
  @type refresh_interval :: 1 | 5 | 10 | 30

  @doc """
  Subscribes to dashboard-relevant PubSub topics for real-time updates.
  """
  def subscribe_dashboard_updates do
    # Subscribe to existing topics that affect dashboard data
    Phoenix.PubSub.subscribe(Notifeye.PubSub, "new_description")
    Phoenix.PubSub.subscribe(Notifeye.PubSub, "updated_description")
    Phoenix.PubSub.subscribe(Notifeye.PubSub, "deleted_description")
    Phoenix.PubSub.subscribe(Notifeye.PubSub, "notification_groups")

    # TODO: Add alert assignments and notifications topics when implemented
    :ok
  end

  @doc """
  Gets dashboard statistics for alerts within the specified time window.
  """
  def get_alert_stats(time_window \\ :week) do
    cutoff_date = get_cutoff_date(time_window)

    with {:ok, total_alerts} <- count_alerts_since(cutoff_date),
         {:ok, severity_breakdown} <- get_alert_severity_breakdown(cutoff_date),
         {:ok, recent_alerts} <- get_recent_alerts(cutoff_date, 10) do
      {:ok,
       %{
         total_alerts: total_alerts,
         severity_breakdown: severity_breakdown,
         recent_alerts: recent_alerts,
         time_window: time_window
       }}
    end
  end

  @doc """
  Gets dashboard statistics for assignments within the specified time window.
  """
  def get_assignment_stats(time_window \\ :week) do
    cutoff_date = get_cutoff_date(time_window)

    with {:ok, total_assignments} <- count_assignments_since(cutoff_date),
         {:ok, status_breakdown} <- get_assignment_status_breakdown(cutoff_date),
         {:ok, recent_assignments} <- get_recent_assignments(cutoff_date, 10) do
      {:ok,
       %{
         total_assignments: total_assignments,
         status_breakdown: status_breakdown,
         recent_assignments: recent_assignments,
         time_window: time_window
       }}
    end
  end

  @doc """
  Gets dashboard statistics for notifications within the specified time window.
  Currently focuses on Oban jobs for notifications.
  """
  def get_notification_stats(time_window \\ :week) do
    # TODO: Implement notification stats from Oban jobs
    # For now, return basic structure
    {:ok,
     %{
       total_notifications: 0,
       delivery_breakdown: %{},
       recent_notifications: [],
       time_window: time_window
     }}
  end

  # Private helper functions

  defp get_cutoff_date(:day), do: DateTime.add(DateTime.utc_now(), -1, :day)
  defp get_cutoff_date(:week), do: DateTime.add(DateTime.utc_now(), -7, :day)
  defp get_cutoff_date(:month), do: DateTime.add(DateTime.utc_now(), -30, :day)

  defp count_alerts_since(cutoff_date) do
    count =
      from(a in Alert, where: a.inserted_at >= ^cutoff_date)
      |> Repo.aggregate(:count)

    {:ok, count}
  end

  defp get_alert_severity_breakdown(cutoff_date) do
    breakdown =
      from(a in Alert,
        where: a.inserted_at >= ^cutoff_date,
        group_by: a.alert_severity,
        select: {a.alert_severity, count(a.id)}
      )
      |> Repo.all()
      |> Enum.into(%{})

    {:ok, breakdown}
  end

  defp get_recent_alerts(cutoff_date, limit) do
    alerts =
      from(a in Alert,
        where: a.inserted_at >= ^cutoff_date,
        order_by: [desc: a.inserted_at],
        limit: ^limit
      )
      |> Repo.all()

    {:ok, alerts}
  end

  defp count_assignments_since(cutoff_date) do
    count =
      from(aa in AlertAssignment, where: aa.inserted_at >= ^cutoff_date)
      |> Repo.aggregate(:count)

    {:ok, count}
  end

  defp get_assignment_status_breakdown(cutoff_date) do
    breakdown =
      from(aa in AlertAssignment,
        where: aa.inserted_at >= ^cutoff_date,
        group_by: aa.status,
        select: {aa.status, count(aa.id)}
      )
      |> Repo.all()
      |> Enum.into(%{})

    {:ok, breakdown}
  end

  defp get_recent_assignments(cutoff_date, limit) do
    assignments =
      from(aa in AlertAssignment,
        where: aa.inserted_at >= ^cutoff_date,
        order_by: [desc: aa.inserted_at],
        limit: ^limit,
        preload: [:user, :alert, :alert_description]
      )
      |> Repo.all()

    {:ok, assignments}
  end
end
