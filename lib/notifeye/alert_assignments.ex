defmodule Notifeye.AlertAssignments do
  @moduledoc """
  The AlertAssignments context.
  """

  import Ecto.Query, warn: false

  alias Notifeye.Accounts
  alias Notifeye.Accounts.Scope
  alias Notifeye.Accounts.User
  alias Notifeye.AlertAssignments.AlertAssignment
  alias Notifeye.Monitoring

  alias Ecto.Multi

  alias Notifeye.Repo

  @doc """
  Returns the list of alert_assignments.

  ## Examples

      iex> list_alert_assignments()
      [%AlertAssignment{}, ...]

  """
  def list_alert_assignments do
    Repo.all(AlertAssignment)
  end

  @doc """
  Gets a single alert_assignment.

  Raises `Ecto.NoResultsError` if the Alert assignment does not exist.

  ## Examples

      iex> get_alert_assignment!(123)
      %AlertAssignment{}

      iex> get_alert_assignment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_alert_assignment!(id) do
    AlertAssignment
    |> Repo.get!(id)
  end

  def get_alert_assignment!(id, preloads) do
    AlertAssignment
    |> Repo.get!(id)
    |> Repo.preload(preloads)
  end

  def get_alert_assignment(id) do
    AlertAssignment
    |> Repo.get(id)
    |> Repo.preload([:user, :alert, :alert_description])
  end

  def get_alert_assignment(%Scope{user: %User{id: user_id}}, id) do
    AlertAssignment
    |> where([a], a.user_id == ^user_id and a.id == ^id)
    |> limit(1)
    |> Repo.one()
    |> case do
      %AlertAssignment{} = as ->
        Repo.preload(as, [:user, :alert, :alert_description])

      nil ->
        nil
    end
  end

  @doc """
  Creates a alert_assignment.

  ## Examples

      iex> create_alert_assignment(%{field: value})
      {:ok, %AlertAssignment{}}

      iex> create_alert_assignment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_alert_assignment(attrs) do
    %AlertAssignment{}
    |> AlertAssignment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a alert_assignment.

  ## Examples

      iex> update_alert_assignment(alert_assignment, %{field: new_value})
      {:ok, %AlertAssignment{}}

      iex> update_alert_assignment(alert_assignment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_alert_assignment(%AlertAssignment{} = alert_assignment, attrs) do
    alert_assignment
    |> AlertAssignment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Acknowledges an alert assignment struct.

  Makes us of `AlertAssignment.acknowledge_changeset/2` to automatically
  update the state to `closed` and fill the respective `metadata` passed 
  via `attrs`.
  """
  def update_acknowledge_assignment(%AlertAssignment{} = alert_assignment, attrs) do
    alert_assignment
    |> AlertAssignment.acknowledge_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a alert_assignment.

  ## Examples

      iex> delete_alert_assignment(alert_assignment)
      {:ok, %AlertAssignment{}}

      iex> delete_alert_assignment(alert_assignment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_alert_assignment(%AlertAssignment{} = alert_assignment) do
    Repo.delete(alert_assignment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking alert_assignment changes.

  ## Examples

      iex> change_alert_assignment(alert_assignment)
      %Ecto.Changeset{data: %AlertAssignment{}}

  """
  def change_alert_assignment(%AlertAssignment{} = alert_assignment, attrs \\ %{}) do
    AlertAssignment.changeset(alert_assignment, attrs)
  end

  @doc """
  Lists all alert assignments for a given alert description.

  ## Examples

      iex> list_alert_assignments_for_alert_description(123)
      [%AlertAssignment{}, ...]

      iex> list_alert_assignments_for_alert_description(456)
      []
  """
  def list_alert_assignments_for_alert_description(alert_description_id) do
    from(
      a in AlertAssignment,
      where: a.alert_description_id == ^alert_description_id,
      order_by: [asc: a.id]
    )
    |> Repo.all()
  end

  @doc """
  Creates atomically and in bulk `%AlertAssignments{}`, associated with `description_id`
  for each user in `users`. If any of the assignments fails during creation, the whole insertion
  is rollbacked and the function returns.

  ## Parameters

  * `users` - String list of the matched usernamed. The function tries to match the username
    to an actual `%User{}`. If it can't, defaults to the `admin` user.

  * `description_id` - The `%AlertDescription{}` id to associate on the assignment.

  * `alert_id` - The `%Alert{}` id to associate on the assignment.

  ## Examples

      iex> create_alert_assignments_bulk(["username1", ..., "usernameN"], 1, "alert-id")
      {:ok, result}

      iex> create_alert_assignments_bulk(["username1", ..., "usernameN"], 2, "alert-id")
      {}:error, failed_operation, changeset, _changes}
  """
  def create_alert_assignments_bulk(users, description_id, alert_id) do
    users
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn {user_match, index}, multi ->
      {params, status} = build_assignment_params(user_match, description_id, alert_id)

      changeset =
        AlertAssignment.changeset(%AlertAssignment{status: status}, params)

      Multi.insert(multi, assignment_key(index), changeset)
    end)
    |> Repo.transaction()
  end

  defp build_assignment_params(user_match, description_id, alert_id) do
    {user_id, is_admin} = resolve_user_id(user_match)
    status = if is_admin, do: :unassigned, else: :open

    # determine if assignment is recurrent
    is_recurrent = recurrent?(user_id, description_id)

    {%{
       match: user_match,
       user_id: user_id,
       alert_id: alert_id,
       alert_description_id: description_id,
       metadata: %{recurrent: is_recurrent}
     }, status}
  end

  defp resolve_user_id(user_match) do
    case Accounts.get_user_by_name_or_alias(user_match) do
      nil -> {Accounts.get_admin_user!().id, true}
      %Accounts.User{id: id} -> {id, false}
    end
  end

  defp assignment_key(index), do: "assignment_#{index}"

  @doc """
  Acknowledges an alert assignment for a given user.

  When acknowledging an assignment, two things can happen:
  1. The user acknowledges the assignment and has its `standing` restored;
  2. The user acknowledges the assignment but doesn't has its `standing` restored.

  To have one's `standing` restored, the following conditions must verify:
  * The assignment is acknwoledged within 24 hours of the incident;
  * The assignment isn't recurrent.

  An assignment is considered recurrent, if there are more than or 3 related
  assignments within 10 days.

  At the end, after acknowledging an assignment, its `status` is set to `:closed`.

  ## Parameters

  * `%Scope{}` - Scope for the current logged in user.
  * `%AlertAssignment{}` - The `%AlertAssignment{}` in question.

  ## Returns

  * `{:ok, final_standing, had_restore}` - If the operation is successfull.
  * `{:error, reason}` - If the operation fails.

  """
  def acknowledge_assignment(%Scope{} = scope, %AlertAssignment{status: :open} = assignment) do
    validate_user!(scope, assignment)

    standing_penalty =
      assignment.alert.alert_severity
      |> Monitoring.calculate_standing_amount_by_severity()

    close_assignment(
      scope,
      assignment,
      standing_penalty,
      eligible_for_restore?(scope, assignment)
    )
  end

  def acknowledge_assignment(
        %Scope{} = _scope,
        %AlertAssignment{status: status} = _assignment
      ) do
    {:error, "assignment cannot be acknowledged, expected status :open but got #{status}"}
  end

  defp validate_user!(%Scope{user: user}, %AlertAssignment{user_id: user_id}) do
    true = user.id == user_id
  end

  defp close_assignment(%Scope{user: %User{} = user}, assignment, standing_penalty, false) do
    assignment_changes = %{
      change_action: :decrease,
      change_amount: standing_penalty
    }

    case update_acknowledge_assignment(assignment, assignment_changes) do
      {:ok, _updated} -> {:ok, user.standing, false}
      {:error, reason} -> {:error, reason}
    end
  end

  defp close_assignment(%Scope{user: %User{} = user}, assignment, standing_penalty, true) do
    restored_standing =
      Accounts.calculate_new_standing(
        user,
        standing_penalty,
        :increase
      )

    assignment_change = %{
      change_action: :increase,
      change_amount: standing_penalty
    }

    Multi.new()
    |> Multi.update(
      :restore_points,
      Accounts.User.standing_changeset(user, %{standing: restored_standing})
    )
    |> Multi.update(
      :close_assignment,
      AlertAssignment.acknowledge_changeset(assignment, assignment_change)
    )
    |> Repo.transaction()
    |> case do
      {:ok, _result} -> {:ok, restored_standing, true}
      {:error, _step, reason, _changes_so_far} -> {:error, reason}
    end
  end

  @doc """
  Determines whether an assignment is eligible for standing restore.

  Returns true if the assignment is acknowledged within 24 hours of it creations
  and if it is not a recurrent issue.
  """
  def eligible_for_restore?(scope, assignment) do
    delta_hours = DateTime.diff(DateTime.utc_now(), assignment.inserted_at, :hour)
    delta_hours < 24 and not recurrent?(scope.user.id, assignment.alert_description_id)
  end

  @doc """
  Returns whether an assignment is considered as recurrent or not.

  By default, one is recurrent if it has happened for the same alert description
  at least 3 times, within 10 days. However this behaviour is configurable via `limit_days`
  and `threshold`.
  """
  def recurrent?(
        user_id,
        description_id,
        limit_days \\ 10,
        threshold \\ 3
      ) do
    since = DateTime.utc_now() |> DateTime.add(-limit_days, :day)

    count =
      AlertAssignment
      |> where([a], a.user_id == ^user_id)
      |> where([a], a.alert_description_id == ^description_id)
      |> where([a], a.inserted_at >= ^since)
      |> Repo.aggregate(:count, :id)

    count >= threshold
  end
end
