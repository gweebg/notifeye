defmodule Notifeye.Workers.Notifier do
  @moduledoc """
  Oban worker for dispaching notifications to end-users from an alert assignment.

  Determines the type of notification to send based on the assignment and the
  user's preferences. Attempts, at most, 3 times to send the notification, and has
  an exponential backoff strategy for retries.
  """

  require Logger

  alias Notifeye.Accounts
  alias Notifeye.Notifications.Dispacher

  use Oban.Worker,
    queue: :notifier,
    max_attempts: 3,
    tags: ["notification"]

  # todo: explore different backoff alternatives
  # todo: or even contextual backoff

  @doc """
  Performs the notifying job.
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"alert_description_id" => alert_description_id}}) do
    admin = Accounts.get_admin_user!()
    description = Notifeye.AlertDescriptions.get_alert_description!(alert_description_id)

    # results is a map from the provider name (string) to a tuple containing
    # the result of the notification sending operation
    {:ok, results} =
      Dispacher.notify(
        admin,
        {:description_created, description}
      )

    # todo: maybe keep the errors as well?
    failed_providers =
      results
      |> Enum.filter(fn {_provider, result} -> match?({:error, _}, result) end)
      |> Enum.map(fn {provider, _result} -> provider end)

    # if all providers fail, we try again, else we complete the job
    if length(failed_providers) == length(Map.keys(results)) do
      {:error, "all providers failed to send notification: #{inspect(failed_providers)}"}
    else
      {:ok, failed_providers}
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: _args}) do
    :ok
  end
end
