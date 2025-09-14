defmodule Notifeye.Workers.Notifier do
  @moduledoc """
  Oban worker for dispaching notifications to end-users from an alert assignment.

  Determines the type of notification to send based on the assignment and the
  user's preferences. Attempts, at most, 3 times to send the notification, and has
  an exponential backoff strategy for retries.
  """

  require Logger

  alias Notifeye.Notifications
  alias Notifeye.Notifications.{Dispatcher, Message, MessageBuilder, RuleEngine}

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
  def perform(%Oban.Job{args: args} = job) do
    args
    |> MessageBuilder.from_args()
    |> RuleEngine.apply()
    |> Dispatcher.notify()
    |> handle_result()
    |> maybe_persist(job)
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

  defp maybe_persist({:ok, %Message{} = message}, %Oban.Job{id: job_id}) do
    store_notification(message, :ok, job_id)
  end

  defp maybe_persist({:error, %Message{} = message}, %Oban.Job{
         id: job_id,
         attempt: attempt,
         max_attempts: max_attempts
       })
       when attempt == max_attempts do
    store_notification(message, :error, job_id)
  end

  defp maybe_persist({:error, %Message{} = _m} = r, %Oban.Job{id: _id}), do: r

  defp store_notification(%Message{} = m, status, job_id) do
    # IO.inspect(m.results, label: "store_notification -->")

    case Notifications.create_notification(m, status, job_id) do
      {:ok, _notification} ->
        :ok

      {:error, changeset} ->
        Logger.error("""
        failed to insert notification:
          oban_job=#{job_id}
          changeset=#{inspect(changeset)}
        """)
    end
  end
end
