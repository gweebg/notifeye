defmodule Notifeye.AlertAssignments do
  @moduledoc """
  The AlertAssignments context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Notifeye.Accounts

  alias Notifeye.Repo

  alias Notifeye.AlertAssignments.AlertAssignment

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
  def get_alert_assignment!(id), do: Repo.get!(AlertAssignment, id)

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

  def create_alert_assignments_bulk(users, description_id) do
    users
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn {user_match, index}, multi ->
      params = build_assignment_params(user_match, description_id)
      changeset = AlertAssignment.changeset(%AlertAssignment{}, params)

      Multi.insert(multi, assignment_key(index), changeset)
    end)
    |> Repo.transaction()
  end

  defp build_assignment_params(user_match, description_id) do
    user_id = resolve_user_id(user_match)

    %{
      match: user_match,
      user_id: user_id,
      alert_description_id: description_id
    }
  end

  defp resolve_user_id(user_match) do
    case Accounts.get_user_by_name_or_alias(user_match) do
      nil -> Accounts.get_admin_user!().id
      %Accounts.User{id: id} -> id
    end
  end

  defp assignment_key(index), do: "assignment_#{index}"
end
