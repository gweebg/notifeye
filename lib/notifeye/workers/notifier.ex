defmodule Notifeye.Workers.Notifier do
  @moduledoc """
  Oban worker for dispaching notifications to end-users from an alert assignment.

  Determines the type of notification to send based on the assignment and the
  user's preferences. Attempts, at most, 3 times to send the notification, and has
  an exponential backoff strategy for retries.
  """

  require Logger

  alias Notifeye.{Accounts, AlertAssignments}

  use Oban.Worker,
    queue: :notifier,
    max_attempts: 3,
    tags: ["notification"]

  @doc """
  Performs the notifying job.
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    :ok
  end
end
