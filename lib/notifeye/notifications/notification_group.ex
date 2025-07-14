defmodule Notifeye.Notifications.NotificationGroup do
  @moduledoc """
  A reusable notification group that defines which users should be notified.

  Notification groups can be assigned to multiple alert descriptions,
  allowing for flexible team-based notification management.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Notifeye.Accounts.User
  alias Notifeye.AlertDescriptions.AlertDescription

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notification_groups" do
    field :name, :string
    field :description, :string

    many_to_many :users, User,
      join_through: "notification_group_users",
      join_keys: [notification_group_id: :id, user_id: :id],
      on_replace: :delete

    has_many :alert_descriptions, AlertDescription

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification_group, attrs) do
    notification_group
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
    # can lead to race conditions
    |> unsafe_validate_unique(:name, Notifeye.Repo)
    # but this "solves it"
    |> unique_constraint(:name)
  end

  @doc """
  Changeset for managing users in a notification group.

  This changeset completely replaces all users in the notification group
  with the provided list. Use this when you want to set the entire user
  list at once (e.g., from a multi-select form).
  """
  def users_changeset(notification_group, users) when is_list(users) do
    notification_group
    |> cast(%{}, [])
    |> put_assoc(:users, users)
  end

  @doc """
  Returns a changeset for adding a user to the notification group.
  """
  def add_user_changeset(notification_group, user) do
    current_users = notification_group.users || []

    if user in current_users do
      notification_group
      |> cast(%{}, [])
      |> add_error(:users, "user is already in this notification group")
    else
      users_changeset(notification_group, [user | current_users])
    end
  end

  @doc """
  Returns a changeset for removing a user from the notification group.
  """
  def remove_user_changeset(notification_group, user) do
    current_users = notification_group.users || []
    updated_users = Enum.reject(current_users, &(&1.id == user.id))

    users_changeset(notification_group, updated_users)
  end
end
