defmodule Notifeye.Monitoring do
  @moduledoc """
  The Monitoring context.
  """

  import Ecto.Query, warn: false
  alias Notifeye.Repo

  alias Notifeye.Monitoring.Alert
  alias Notifeye.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any alert changes.

  The broadcasted messages match the pattern:

    * {:created, %Alert{}}
    * {:updated, %Alert{}}
    * {:deleted, %Alert{}}

  """
  def subscribe_alerts(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Notifeye.PubSub, "user:#{key}:alerts")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Notifeye.PubSub, "user:#{key}:alerts", message)
  end

  @doc """
  Returns the list of alerts.

  ## Examples

      iex> list_alerts(scope)
      [%Alert{}, ...]

  """
  def list_alerts(%Scope{} = scope) do
    Repo.all(from alert in Alert, where: alert.user_id == ^scope.user.id)
  end

  @doc """
  Lists all alerts created since a specific timestamp.

  This function retrieves alerts that were created after the provided timestamp,
  allowing for incremental fetching of new alerts.

  ## Parameters

  - `since` - A timestamp (DateTime or Unix timestamp) representing the earliest
    creation time for alerts to be included in the results

  ## Returns

  - `{:ok, alerts}` - A list of alert structs created since the specified timestamp
  - `{:error, reason}` - An error tuple if the operation fails

  ## Examples

      iex> list_alerts_since(~U[2024-01-01 00:00:00Z])
      {:ok, [%Alert{}, %Alert{}]}

      iex> list_alerts_since(1704067200)
      {:ok, []}

  """
  def list_alerts_since(description_id, opts \\ []) do
    interval = Keyword.get(opts, :interval, 48 * 60 * 60)
    limit = Keyword.get(opts, :limit, 10)

    Alert
    |> where([alert], alert.logz_id == ^description_id)
    |> where([alert], alert.inserted_at >= ago(^interval, "second"))
    |> limit(^limit)
    |> Repo.all()
  end

  def total_count(for: description_id) do
    Alert
    |> where([a], a.logz_id == ^description_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a single alert.

  Raises `Ecto.NoResultsError` if the Alert does not exist.

  ## Examples

      iex> get_alert!(123)
      %Alert{}

      iex> get_alert!(456)
      ** (Ecto.NoResultsError)

  """
  def get_alert!(%Scope{} = scope, id) do
    Repo.get_by!(Alert, id: id, user_id: scope.user.id)
  end

  def get_alert!(id) do
    Repo.get_by!(Alert, id: id)
  end

  @doc """
  Returns an alert that matches a given `%AlertDescription{}` id.

  ## Examples

      iex> get_alert_for_description!(1)
      %Alert{}

      iex> get_alert_for_description!(-1)
      ** (Ecto.NoResultsError)

  """
  def get_alert_for_description!(description_id) do
    from(
      alert in Alert,
      where: alert.logz_id == ^description_id,
      limit: 1
    )
    |> Repo.one!()
  end

  @doc """
  Creates a alert.

  ## Examples

      iex> create_alert(%{field: value})
      {:ok, %Alert{}}

      iex> create_alert(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_alert(%Scope{} = scope, attrs) do
    with {:ok, alert = %Alert{}} <-
           %Alert{}
           |> Alert.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, alert})
      {:ok, alert}
    end
  end

  @doc """
  Updates a alert.

  ## Examples

      iex> update_alert(alert, %{field: new_value})
      {:ok, %Alert{}}

      iex> update_alert(alert, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_alert(%Scope{} = scope, %Alert{} = alert, attrs) do
    true = alert.user_id == scope.user.id

    with {:ok, alert = %Alert{}} <-
           alert
           |> Alert.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, alert})
      {:ok, alert}
    end
  end

  @doc """
  Deletes a alert.

  ## Examples

      iex> delete_alert(alert)
      {:ok, %Alert{}}

      iex> delete_alert(alert)
      {:error, %Ecto.Changeset{}}

  """
  def delete_alert(%Scope{} = scope, %Alert{} = alert) do
    true = alert.user_id == scope.user.id

    with {:ok, alert = %Alert{}} <-
           Repo.delete(alert) do
      broadcast(scope, {:deleted, alert})
      {:ok, alert}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking alert changes.

  ## Examples

      iex> change_alert(alert)
      %Ecto.Changeset{data: %Alert{}}

  """
  def change_alert(%Scope{} = scope, %Alert{} = alert, attrs \\ %{}) do
    true = alert.user_id == scope.user.id

    Alert.changeset(alert, attrs, scope)
  end

  @doc """
  Returns the value to increase/decrease on the standing value for an user.

  ## Examples

      iex> calculate_standing_amount_by_severity("low")
      1

      iex> calculate_standing_amount_by_severity("something")
      0
  """
  def calculate_standing_amount_by_severity("low"), do: 1
  def calculate_standing_amount_by_severity("medium"), do: 2
  def calculate_standing_amount_by_severity("high"), do: 3
  def calculate_standing_amount_by_severity(_severity), do: 0
end
