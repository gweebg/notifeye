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

  @doc """
  Returns an alert assignment by its id, fully preloaded with its associated
  `user`, `alert` and `alert_description`.
  """
  def get_alert_assignment(id) do
    AlertAssignment
    |> Repo.get(id)
    |> Repo.preload([:user, :alert, :alert_description])
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
      order_by: [asc: a.id],
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Returns a list of alert assignments for a given alert description that were inserted
  within the past `interval` seconds.

  ## Parameters

  - `description_id` (`integer`): The ID of the alert description to filter assignments by.
  - `opts` (`Keyword` list, optional):
    - `:interval` (`integer`, default: `172800`): Time interval in seconds to look back from the current time. Defaults to 48 hours (`48 * 60 * 60`).
    - `:limit` (`integer`, default: `10`): Maximum number of records to return.

  ## Preloads

  This function preloads the `:user` association for each assignment.
  """
  def list_assignments_since(description_id, opts \\ []) do
    interval = Keyword.get(opts, :interval, 48 * 60 * 60)
    limit = Keyword.get(opts, :limit, 10)

    AlertAssignment
    |> where([a], a.alert_description_id == ^description_id)
    |> where([alert], alert.inserted_at >= ago(^interval, "second"))
    |> limit(^limit)
    |> preload([:user])
    |> Repo.all()
  end

  @doc """
  Returns the total number of alert assignments.

  ## Options

    - `:for` — (optional) filters the count by `alert_description_id`.
  """
  def total_count(opts \\ []) do
    query = AlertAssignment

    query =
      case Keyword.get(opts, :for) do
        nil -> query
        description_id -> where(query, [a], a.alert_description_id == ^description_id)
      end

    Repo.aggregate(query, :count, :id)
  end

  @doc """
  Given the resulting user matches from applying an alert description pattern
  onto some alert samples, this function tries to match the user match with
  an `%User{}`, creating the assignment and updating its standing.

  If the match doesn't correspond to an user, then the assignment is created
  for the `:admin` with the status `:unassigned`.
  """
  def create_assignments_from_matches(users, desc_id, alert_id) when is_list(users) do
    users
    |> Enum.map(fn user_match ->
      case process_assignment(user_match, desc_id, alert_id) do
        {:ok, assignment} -> {:ok, Repo.preload(assignment, [:user, :alert])}
        error -> error
      end
    end)
  end

  defp resolve_user(user_match) do
    case Accounts.get_user_by_name_or_alias(user_match) do
      nil -> {Accounts.get_admin_user!().id, true}
      %Accounts.User{id: id} -> {id, false}
    end
  end

  defp process_assignment(user_match, desc_id, alert_id) do
    Multi.new()
    |> Multi.run(:resolved_user, fn _repo, _changes ->
      {user_id, is_admin} = resolve_user(user_match)
      {:ok, %{user_id: user_id, is_admin: is_admin}}
    end)
    |> Multi.run(:assignment, fn _repo,
                                 %{resolved_user: %{user_id: user_id, is_admin: is_admin}} ->
      assignment_changeset =
        build_assignment_changeset(user_id, is_admin, user_match, desc_id, alert_id)

      if assignment_changeset.valid? do
        Repo.insert(assignment_changeset)
      else
        {:error, assignment_changeset}
      end
    end)
    |> Multi.run(:update_standing, fn _repo, %{assignment: assignment} ->
      maybe_update_standing(assignment)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{assignment: assignment}} -> {:ok, assignment}
      error -> error
    end
  end

  defp build_assignment_changeset(user_id, is_admin, user_match, desc_id, alert_id) do
    status = if is_admin, do: :unassigned, else: :open

    AlertAssignment.changeset(%AlertAssignment{}, %{
      status: status,
      match: user_match,
      user_id: user_id,
      alert_id: alert_id,
      alert_description_id: desc_id,
      metadata: %{
        recurrent: recurrent?(user_id, desc_id)
      }
    })
  end

  defp maybe_update_standing(%AlertAssignment{status: :open, user_id: user_id, alert_id: alert_id}) do
    alert = Monitoring.get_alert!(alert_id)

    Accounts.update_standing(
      Accounts.get_user!(user_id),
      Monitoring.calculate_standing_amount_by_severity(alert.alert_severity),
      :decrease
    )
  end

  defp maybe_update_standing(_assignment), do: {:ok, :noop}

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
      eligible_for_restore?(assignment)
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
      {:ok, %AlertAssignment{} = updated} -> {:ok, updated, user.standing, false}
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
      # `Multi.transaction` returns an assignment map
      {:ok, %{close_assignment: %AlertAssignment{} = updated}} ->
        {:ok, updated, restored_standing, true}

      {:error, _step, reason, _changes_so_far} ->
        {:error, reason}
    end
  end

  @doc """
  Determines whether an assignment is eligible for standing restore.

  Returns true if the assignment is acknowledged within 24 hours of it creations
  and if it is not a recurrent issue.
  """
  def eligible_for_restore?(assignment) do
    delta_hours = DateTime.diff(DateTime.utc_now(), assignment.inserted_at, :hour)
    delta_hours < 24 and not assignment.metadata.recurrent
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

  @doc """
  Transfers an assignment from one user to another.

  This function can only be executed by admin users and is used to reassign
  an alert assignment to a different user. The assignment must be in :open or :unassigned status.

  ## Parameters

  * `%Scope{}` - Admin scope for the current logged in user.
  * `%AlertAssignment{}` - The assignment to transfer.
  * `target_user_id` - The ID of the user to transfer the assignment to.

  ## Returns

  * `{:ok, %AlertAssignment{}}` - If the transfer is successful.
  * `{:error, reason}` - If the transfer fails.
  """
  def transfer_assignment(
        %Scope{user: %User{role: :admin}} = _scope,
        %AlertAssignment{status: status} = assignment,
        target_user_id
      )
      when status in [:open, :unassigned] do
    target_user = Accounts.get_user!(target_user_id)

    # Update assignment with new user and recalculate recurrency
    is_recurrent = recurrent?(target_user.id, assignment.alert_description_id)

    update_attrs = %{
      user_id: target_user.id,
      status: :open,
      metadata: %{recurrent: is_recurrent}
    }

    case update_alert_assignment(assignment, update_attrs) do
      {:ok, updated_assignment} ->
        {:ok, Repo.preload(updated_assignment, [:user, :alert, :alert_description])}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def transfer_assignment(%Scope{user: %User{role: role}}, _assignment, _target_user_id) do
    {:error, "Only admin users can transfer assignments, current role: #{role}"}
  end

  def transfer_assignment(_scope, %AlertAssignment{status: status}, _target_user_id) do
    {:error,
     "Assignment cannot be transferred, expected status :open or :unassigned but got #{status}"}
  end

  @doc """
  Force acknowledges an assignment without validation.

  This function can only be executed by admin users and bypasses the normal
  acknowledgment validation (phrase matching, ownership checks).

  ## Parameters

  * `%Scope{}` - Admin scope for the current logged in user.
  * `%AlertAssignment{}` - The assignment to force acknowledge.

  ## Returns

  * `{:ok, %AlertAssignment{}, current_standing, restored?}` - If successful.
  * `{:error, reason}` - If the operation fails.
  """
  def force_acknowledge_assignment(
        %Scope{user: %User{role: :admin}} = _scope,
        %AlertAssignment{status: status} = assignment
      )
      when status in [:open] do
    # Get the assignment owner's current standing for restoration calculation
    assignment_owner = Accounts.get_user!(assignment.user_id)
    owner_scope = Scope.for_user(assignment_owner)

    standing_penalty =
      assignment.alert.alert_severity
      |> Monitoring.calculate_standing_amount_by_severity()

    can_restore = status == :open && eligible_for_restore?(assignment)

    close_assignment(
      owner_scope,
      assignment,
      standing_penalty,
      can_restore
    )
  end

  def force_acknowledge_assignment(%Scope{user: %User{role: role}}, _assignment) do
    {:error, "Only admin users can force acknowledge assignments, current role: #{role}"}
  end

  def force_acknowledge_assignment(_scope, %AlertAssignment{status: status}) do
    {:error, "Assignment cannot be force acknowledged, expected status :open but got #{status}"}
  end

  @doc """
  Lists all users except the specified user ID.

  This is useful for populating transfer assignment dropdowns where
  we don't want to include the currently assigned user.

  ## Parameters

  * `exclude_user_id` - The user ID to exclude from the results.

  ## Returns

  * A list of users with id, username, and email fields.
  """
  def list_users_except(exclude_user_id) do
    from(u in User,
      where: u.id != ^exclude_user_id,
      select: %{id: u.id, username: u.username, email: u.email},
      order_by: [u.username, u.email]
    )
    |> Repo.all()
  end
end
