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
end
