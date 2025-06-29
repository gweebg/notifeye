defmodule Notifeye.Workers.Alerts do
  @moduledoc """
  Oban worker for processing a new alert.

  Starts by verifying whether the alert is already registered in the system, followed by
  processing the alert based on its description. If the alert is not registered, it creates a new
  alert description for the operator to fill in. If the alert is registered, it enqueues
  the alert for further processing.

  TODO: Dig into Worker settings, p.e. `limit`.
  """

  alias Notifeye.{Accounts, AlertDescriptions, AlertAssignments}
  alias Notifeye.Monitoring.Alert
  alias Notifeye.AlertDescriptions.AlertDescription

  use Oban.Worker,
    queue: :processing,
    max_attempts: 3,
    tags: ["alert"]

  @doc """
  Performs the alert processing job.
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: %Alert{} = alert}) do
    case AlertDescriptions.get_alert_description(alert.logz_id) do
      # create new alert description if it does not exist
      nil -> AlertDescriptions.create_alert_description(%{id: alert.logz_id})
      # process the alert if information about the alert is available
      %AlertDescription{} = description -> process_alert(description, alert)
    end
  end

  defp process_alert(%AlertDescription{} = description, %Alert{} = alert) do
    case AlertDescriptions.maybe_match_samples(description.pattern, alert.alert_event_samples) do
      nil -> {:cancel, "pattern did not match any part of the alert event samples"}
      {:error, reason} -> {:cancel, reason}
      user -> verify_user_match(user, description)
    end
  end

  defp verify_user_match(user_match, %AlertDescription{} = description)
       when is_binary(user_match) do
    # check if user is registered or matches any of its aliases
    # if it does create a new alert assignment for the respective user
    # else create it for the admin user
    user_id =
      case Accounts.get_user_by_name_or_alias(user_match) do
        nil -> Accounts.get_admin_user!().id
        %Accounts.User{id: id} -> id
      end

    case AlertAssignments.create_alert_assignment(%{
           match: user_match,
           user_id: user_id,
           alert_description_id: description.id
         }) do
      {:ok, _assignment} ->
        # create new job in notification queue
        :ok

      {:error, changeset} ->
        {:cancel, "failed to create alert assignment: #{inspect(changeset.errors)}"}
    end
  end
end
