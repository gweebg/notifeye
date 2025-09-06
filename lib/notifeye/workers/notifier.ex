defmodule Notifeye.Workers.Notifier do
  @moduledoc """
  Oban worker for dispaching notifications to end-users from an alert assignment.

  Determines the type of notification to send based on the assignment and the
  user's preferences. Attempts, at most, 3 times to send the notification, and has
  an exponential backoff strategy for retries.
  """

  alias Notifeye.Notifications.{Dispatcher, MessageBuilder, RuleEngine, Message}

  use Oban.Worker,
    queue: :notifier,
    max_attempts: 3,
    tags: ["notification"]

  # def backoff(attempt) do
  #   # start at 15 min, then 30, 60...
  #   base = :math.pow(2, attempt - 1) * 15 * 60
  #   # add 0–5 min jitter
  #   jitter = :rand.uniform(5 * 60)
  #   # cap at 2 hours max
  #   min(round(base + jitter), 1 * 60 * 60)
  # end

  @doc """
  Performs the notifying job.
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    args
    |> MessageBuilder.from_args()
    |> RuleEngine.apply()
    |> Dispatcher.notify()
    |> handle_result()
  end

  defp handle_result(%Message{results: results} = message) do
    succeeded =
      results
      |> Enum.filter(fn {_provider, res} -> match?({:ok, _}, res) end)
      |> Enum.map(&elem(&1, 0))

    cond do
      length(succeeded) == map_size(results) ->
        {:ok, message}

      succeeded != [] ->
        {:ok, message}

      true ->
        {:error, message}
    end
  end
end
