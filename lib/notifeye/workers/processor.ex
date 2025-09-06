defmodule Notifeye.Workers.Processor do
  @moduledoc """
  Oban worker for processing a new alert.

  Starts by verifying whether the alert is already registered in the system, followed by
  processing the alert based on its description. If the alert is not registered, it creates a new
  alert description for the operator to fill in. If the alert is registered, it enqueues
  the alert for further processing.
  """

  require Logger

  alias Notifeye.{AlertDescriptions, AlertAssignments, Notifications}
  alias Notifeye.AlertDescriptions.AlertDescription
  alias Notifeye.AlertAssignments.AlertAssignment
  alias Notifeye.Workers

  use Oban.Worker,
    queue: :processing,
    max_attempts: 3,
    tags: ["alert"]

  @lead_threshold 5
  @severity_threshold "high"

  defmodule Context do
    @moduledoc """
    This is  a simple struct to keep track of the arguments passed onto the
    `Oban.Job{}` struct, when a new job is queued.
    """

    defstruct ~w(alert_id logz_id samples description)a

    def init(alert_id, logz_id, samples) do
      %__MODULE__{
        alert_id: alert_id,
        logz_id: logz_id,
        samples: samples
      }
    end

    def with_description(%__MODULE__{} = context, %AlertDescription{} = description) do
      %{context | description: description}
    end
  end

  @doc """
  Performs the alert processing job.
  """
  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"id" => alert_id, "logz_id" => logz_id, "alert_event_samples" => samples}
      }) do
    context = Context.init(alert_id, logz_id, samples)

    case AlertDescriptions.get_alert_description(context.logz_id) do
      # create new alert description if it does not exist
      nil ->
        create_description(context.logz_id)

      # process the alert if information about the alert is available
      %AlertDescription{} = description ->
        context
        |> Context.with_description(description)
        |> process_alert()
    end
  end

  defp create_description(logz_id) do
    with {:ok, %AlertDescription{} = description} <-
           AlertDescriptions.create_alert_description(%{id: logz_id}) do
      enqueue_new_alert_notification(description)
      {:ok, description}
    end
  end

  defp process_alert(%Context{description: %AlertDescription{id: id, state: :disabled}}) do
    {:ok, "description #{id} is disabled"}
  end

  defp process_alert(%Context{description: description} = context) do
    case AlertDescriptions.maybe_match_samples(description.pattern, context.samples) do
      nil ->
        {:cancel, "pattern #{description.pattern} does not match any part of the alert samples"}

      {:error, reason} ->
        {:cancel, reason}

      users ->
        create_assignments_and_notify(context, users)
    end
  end

  defp create_assignments_and_notify(%Context{description: description} = context, users) do
    assignments =
      AlertAssignments.create_assignments_from_matches(
        users,
        description.id,
        context.alert_id
      )

    for {status, result} <- assignments do
      # notify based on the result
      handle_assignment_notifications(status, result, context)
    end

    assignments
    |> Enum.any?(fn {status, _} -> match?(:error, status) end)
    |> case do
      true -> {:cancel, assignments}
      _ -> {:ok, assignments}
    end
  end

  defp handle_assignment_notifications(:ok, %AlertAssignment{} = assignment, %Context{
         description: description
       }) do
    if description.state == :enabled do
      enqueue_assignment_notification(assignment)
    end

    if description.notification_group_id != nil and
         description.state in [:enabled, :grouponly] do
      enqueue_group_notifications(assignment, description)
    end
  end

  defp handle_assignment_notifications(:error, error, context) do
    Logger.error("failed creating assignment", error: error, alert_id: context.alert_id)
  end

  defp enqueue_assignment_notification(%AlertAssignment{} = assignment) do
    maybe_notify_lead(assignment)

    %{assignment_id: assignment.id}
    |> Workers.Notifier.new()
    |> Oban.insert()
  end

  defp enqueue_group_notifications(
         %AlertAssignment{} = assignment,
         %AlertDescription{} = description
       ) do
    for %{id: user_id} <- Notifications.list_group_users(description) do
      %{
        user_id: user_id,
        group_id: description.notification_group_id,
        assignment_id: assignment.id
      }
      |> Workers.Notifier.new()
      |> Oban.insert()
    end
  end

  defp enqueue_new_alert_notification(%AlertDescription{} = description) do
    %{description_id: description.id}
    |> Workers.Notifier.new()
    |> Oban.insert()
  end

  defp maybe_notify_lead(%AlertAssignment{} = assignment) do
    user = assignment.user

    if user.lead_id != nil &&
         (user.standing < @lead_threshold ||
            assignment.alert.alert_severity == @severity_threshold) do
      %{
        lead_id: user.lead_id,
        assignment_id: assignment.id
      }
      |> Notifeye.Workers.Notifier.new()
      |> Oban.insert()
    end
  end
end
