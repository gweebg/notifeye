defmodule Notifeye.Workers.Processor do
  @moduledoc """
  Oban worker for processing a new alert.

  Starts by verifying whether the alert is already registered in the system, followed by
  processing the alert based on its description. If the alert is not registered, it creates a new
  alert description for the operator to fill in. If the alert is registered, it enqueues
  the alert for further processing.

  TODO: Dig into Worker settings, p.e. `limit`.
  """

  alias Notifeye.{AlertDescriptions, AlertAssignments, Notifications}
  alias Notifeye.AlertDescriptions.AlertDescription
  alias Notifeye.AlertAssignments.AlertAssignment

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
    with {:ok, %AlertDescription{} = description} <-
           AlertDescriptions.create_alert_description(%{id: logz_id}) do
      enqueue_new_alert_notification(description)
      {:ok, description}
    end
  end

  defp process_alert(%AlertDescription{state: :disabled} = description, _samples) do
    {:cancel, "alert (#{description.id}) is disabled"}
  end

  defp process_alert(%AlertDescription{} = description, samples) do
    case AlertDescriptions.maybe_match_samples(description.pattern, samples) do
      nil ->
        {:cancel, "pattern #{description.pattern} does not match any part of the alert samples"}

      {:error, reason} ->
        {:cancel, reason}

      users ->
        create_assignments_and_notify(users, description)
    end
  end

  defp create_assignments_and_notify(users, %AlertDescription{state: state} = description) do
    # we either create assignments for all users or for none
    # create_alert_assignments_bulk/2 is atomic and only succeeds if all assignments are created
    # if at least one error occurs, no assignments are created and the tx are rolled back
    case AlertAssignments.create_alert_assignments_bulk(users, description.id) do
      {:ok, assignments_map} ->
        assignments = Map.values(assignments_map)

        # if desc. is enabled, notify the assigned user(s)
        if state == :enabled do
          enqueue_assignment_notifications(assignments)
        end

        # if only enabled for notification group, notify group members
        # `and state == :grouponly` is not necessary here
        if description.notification_group_id and state == :grouponly do
          enqueue_group_notifications(assignments, description)
        end

        {:ok, assignments}

      # Ecto.Multi error
      {:error, failed_operation, changeset, _changes} ->
        {:error,
         "failed to create alert assignments: #{failed_operation} - #{inspect(changeset)}"}
    end
  end

  # notify users who were assigned to handle this alert
  defp enqueue_assignment_notifications(assignments) when is_list(assignments) do
    assignments
    |> Enum.each(fn %AlertAssignment{} = assignment ->
      %{assignment_id: assignment.id}
      |> Notifeye.Workers.Notifier.new()
      |> Oban.insert()
    end)
  end

  # notify all users in the notification group about the alert
  defp enqueue_group_notifications(
         assignments,
         %AlertDescription{} = description
       ) do
    users = Notifications.list_users_to_notify_for_alert(description)

    for %AlertAssignment{id: assignment_id} <- assignments,
        %{id: user_id} <- users do
      %{
        user_id: user_id,
        alert_description_id: description.id,
        assignment_id: assignment_id
      }
      |> Notifeye.Workers.Notifier.new()
      |> Oban.insert()
    end
  end

  # notify about a new alert description that needs to be configured
  defp enqueue_new_alert_notification(%AlertDescription{} = description) do
    %{alert_description_id: description.id}
    |> Notifeye.Workers.Notifier.new()
    |> Oban.insert()
  end
end
