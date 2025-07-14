defmodule Notifeye.Workers.Alerts do
  @moduledoc """
  Oban worker for processing a new alert.

  Starts by verifying whether the alert is already registered in the system, followed by
  processing the alert based on its description. If the alert is not registered, it creates a new
  alert description for the operator to fill in. If the alert is registered, it enqueues
  the alert for further processing.

  TODO: Dig into Worker settings, p.e. `limit`.
  """

  alias Notifeye.{AlertDescriptions, AlertAssignments}
  alias Notifeye.AlertDescriptions.AlertDescription

  use Oban.Worker,
    queue: :processing,
    max_attempts: 3,
    tags: ["alert"]

  @doc """
  Performs the alert processing job.
  """
  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"logz_id" => logz_id, "alert_event_samples" => samples}
      }) do
    case AlertDescriptions.get_alert_description(logz_id) do
      # create new alert description if it does not exist
      nil -> create_description(logz_id)
      # process the alert if information about the alert is available
      %AlertDescription{} = description -> process_alert(description, samples)
    end
  end

  defp create_description(logz_id) do
    case AlertDescriptions.create_alert_description(%{id: logz_id}) do
      {:ok, %AlertDescription{} = description} = result ->
        description
        |> Notifeye.Workers.Notifier.new()
        |> Oban.insert()

        result

      error ->
        error
    end
  end

  defp process_alert(%AlertDescription{enabled: true} = description, samples) do
    case AlertDescriptions.maybe_match_samples(description.pattern, samples) do
      nil -> {:cancel, "pattern did not match any part of the alert event samples"}
      {:error, reason} -> {:cancel, reason}
      users -> enqueue_matches(users, description)
    end
  end

  defp process_alert(%AlertDescription{enabled: false} = _description, _samples) do
    {:cancel, "alert description found, but it is disabled"}
  end

  defp enqueue_matches(users, %AlertDescription{} = description)
       when is_list(users) do
    case AlertAssignments.create_alert_assignments_bulk(users, description.id) do
      {:ok, assignments_map} ->
        assignments_map
        |> Map.values()
        |> enqueue_notifications()

        :ok

      {:error, failed_operation, changeset, _changes} ->
        {:error,
         "Failed to create alert assignments: #{failed_operation} - #{inspect(changeset)}"}
    end
  end

  defp enqueue_notifications(assignments) do
    assignments
    |> Enum.each(fn assignment ->
      %{assignment_id: assignment.id}
      |> Notifeye.Workers.Notifier.new()
      |> Oban.insert()
    end)
  end
end
