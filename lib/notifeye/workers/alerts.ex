defmodule Notifeye.Workers.Alerts do
  @moduledoc """
  Oban worker for processing a new alert.

  Starts by verifying whether the alert is already registered in the system, followed by
  processing the alert based on its description. If the alert is not registered, it creates a new
  alert description for the operator to fill in. If the alert is registered, it enqueues
  the alert for further processing.

  TODO: Dig into Worker settings, p.e. `limit`.
  """

  alias Notifeye.Monitoring.Alert
  alias Notifeye.AlertDescriptions
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

  @doc """
  1. Get alert description pattern and run it agains the alert_event_samples.
  2. If anything matches:
    2.1. If if resembles an username/email, extract it and assign the alert to the user.
      2.1.1. If the user is not registerd, assign it to the user `admin`;
      2.1.2. Else, assign the alert to the user.
    2.2. Else, cancel the job with the reason that the alert is not relevant to any known user.
  3. Else, cancel the job with the reason that the alert did not match any known user.
  4. Enqueue a new job to notify the user about the alert.
  """
  defp process_alert(%AlertDescription{} = description, %Alert{} = alert) do
  end
end
