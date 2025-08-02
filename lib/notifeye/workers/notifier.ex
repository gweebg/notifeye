defmodule Notifeye.Workers.Notifier do
  @moduledoc """
  Oban worker for dispaching notifications to end-users from an alert assignment.

  Determines the type of notification to send based on the assignment and the
  user's preferences. Attempts, at most, 3 times to send the notification, and has
  an exponential backoff strategy for retries.
  """

  require Logger

  alias Notifeye.Notifications.Dispacher
  alias Notifeye.{Accounts, AlertAssignments, AlertDescriptions, Notifications}

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
  def perform(%Oban.Job{args: args}) do
    {user, operation} = get_context(for: args)

    # results is a map from the provider name (string) to a tuple containing
    # the result of the notification sending operation
    # %{provider_name => {:ok|:error, whatever}}
    {:ok, results} =
      Dispacher.notify(user, operation)

    # todo: what to do with the errors?
    failed_providers =
      results
      |> Map.filter(fn {_provider, result} -> match?({:error, _}, result) end)
      |> Map.keys()

    # if all providers fail, we try again, else we complete the job
    if length(failed_providers) == length(Map.keys(results)) do
      {:error, "all providers failed to send notification: #{inspect(failed_providers)}"}
    else
      # at least one provider successfully notified the user
      {:ok, failed_providers}
    end
  end

  # follows context types defined in `Notifeye.Notifications.Behaviour`
  defp get_context(for: %{"description_id" => alert_description_id}) do
    {
      Accounts.get_admin_user!(),
      {:description_created, AlertDescriptions.get_alert_description!(alert_description_id)}
    }
  end

  defp get_context(
         for: %{"user_id" => user_id, "group_id" => group_id, "assignment_id" => assignment_id}
       ) do
    user = Accounts.get_user!(user_id)
    assignment = AlertAssignments.get_alert_assignment!(assignment_id, [:alert])
    group = Notifications.get_notification_group!(group_id)

    {user, {:group_notification, group, assignment}}
  end

  defp get_context(for: %{"lead_id" => lead_id, "assignment_id" => assignment_id}) do
    assignment =
      AlertAssignments.get_alert_assignment!(
        assignment_id,
        [:user, :alert]
      )

    lead = Accounts.get_user!(lead_id)

    {lead, {:lead_notification, assignment}}
  end

  defp get_context(for: %{"assignment_id" => assignment_id}) do
    assignment =
      AlertAssignments.get_alert_assignment!(
        assignment_id,
        [:user, :alert]
      )

    {assignment.user, {:assignment_created, assignment}}
  end
end
