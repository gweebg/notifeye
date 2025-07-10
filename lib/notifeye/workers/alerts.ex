defmodule Notifeye.Workers.Alerts do
  @moduledoc """
  Oban worker for processing a new alert.

  Starts by verifying whether the alert is already registered in the system, followed by
  processing the alert based on its description. If the alert is not registered, it creates a new
  alert description for the operator to fill in. If the alert is registered, it enqueues
  the alert for further processing.

  TODO: Dig into Worker settings, p.e. `limit`.
  """

  require Logger

  alias Notifeye.{Accounts, AlertDescriptions, AlertAssignments}
  alias Notifeye.AlertDescriptions.AlertDescription

  use Oban.Worker,
    queue: :processing,
    max_attempts: 3,
    tags: ["alert"]

  @doc """
  Performs the alert processing job.
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    logz_id = Map.get(args, "logz_id")
    samples = Map.get(args, "alert_event_samples")

    case AlertDescriptions.get_alert_description(logz_id) do
      # create new alert description if it does not exist
      nil -> AlertDescriptions.create_alert_description(%{id: logz_id})
      # process the alert if information about the alert is available
      %AlertDescription{} = description -> process_alert(description, samples)
    end
  end

  defp process_alert(%AlertDescription{enabled: true} = description, samples) do
    case AlertDescriptions.maybe_match_samples(description.pattern, samples) do
      nil -> {:cancel, "pattern did not match any part of the alert event samples"}
      {:error, reason} -> {:cancel, reason}
      users -> verify_matches(users, description)
    end
  end

  defp process_alert(%AlertDescription{enabled: false} = _description, _samples) do
    {:cancel, "alert description found, but it is disabled"}
  end

  # bellow here, must be another worker doing the matching
  # because we want to be able to fail jobs

  defp verify_matches(users, %AlertDescription{} = description)
       when is_list(users) do
    errors =
      users
      |> Enum.map(&verify_user_match(&1, description))
      |> Enum.filter(&match?({:error, _}, &1))

    case errors do
      [] ->
        :ok

      errors ->
        Logger.error(
          "Failed to create #{length(errors)} out of #{length(users)} alert assignments: #{inspect(errors)}"
        )

        # don't fail the job - accept partial success
        :ok
    end
  end

  defp verify_user_match(user, description) do
    # check if user is registered or matches any of its aliases
    # if it does create a new alert assignment for the respective user
    # else create it for the admin user
    user_id =
      case Accounts.get_user_by_name_or_alias(user) do
        nil -> Accounts.get_admin_user!().id
        %Accounts.User{id: id} -> id
      end

    case AlertAssignments.create_alert_assignment(%{
           match: user,
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
