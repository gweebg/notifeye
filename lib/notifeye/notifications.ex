defmodule Notifeye.Notifications do
  @moduledoc """
  The Notifications context.

  Handles notification groups and their relationships with users and alert descriptions.
  """

  import Ecto.Query, warn: false

  alias Notifeye.Repo
  alias Notifeye.Notifications.NotificationGroup
  alias Notifeye.Accounts.User
  alias Notifeye.AlertDescriptions.AlertDescription

  @doc """
  Subscribes to notifications about notification group changes.

  The broadcasted messages match the pattern:

    * {:created, %NotificationGroup{}}
    * {:updated, %NotificationGroup{}}
    * {:deleted, %NotificationGroup{}}
    * {:user_added, %NotificationGroup{}, %User{}}
    * {:user_removed, %NotificationGroup{}, %User{}}

  """
  def subscribe_notification_groups do
    Phoenix.PubSub.subscribe(Notifeye.PubSub, "notification_groups")
  end

  defp broadcast(message) do
    Phoenix.PubSub.broadcast(Notifeye.PubSub, "notification_groups", message)
  end

  ## Notification Groups

  @doc """
  Returns the list of notification groups.

  ## Examples

      iex> list_notification_groups()
      [%NotificationGroup{}, ...]

  """
  def list_notification_groups do
    Repo.all(NotificationGroup)
  end

  @doc """
  Returns the list of notification groups with users preloaded.
  """
  def list_notification_groups_with_users do
    NotificationGroup
    |> preload(:users)
    |> Repo.all()
  end

  @doc """
  Gets a single notification group.

  Raises `Ecto.NoResultsError` if the notification group does not exist.

  ## Examples

      iex> get_notification_group!(123)
      %NotificationGroup{}

      iex> get_notification_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_notification_group!(id), do: Repo.get!(NotificationGroup, id)

  @doc """
  Gets a single notification group with associations preloaded.
  """
  def get_notification_group_with_users!(id) do
    NotificationGroup
    |> preload(:users)
    |> Repo.get!(id)
  end

  @doc """
  Creates a notification group.

  ## Examples

      iex> create_notification_group(%{name: "Frontend Team"})
      {:ok, %NotificationGroup{}}

      iex> create_notification_group(%{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_notification_group(attrs \\ %{}) do
    with {:ok, notification_group} <-
           %NotificationGroup{}
           |> NotificationGroup.changeset(attrs)
           |> Repo.insert() do
      broadcast({:created, notification_group})
      {:ok, notification_group}
    end
  end

  @doc """
  Updates a notification group.

  ## Examples

      iex> update_notification_group(notification_group, %{name: "Updated Team"})
      {:ok, %NotificationGroup{}}

      iex> update_notification_group(notification_group, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def update_notification_group(%NotificationGroup{} = notification_group, attrs) do
    with {:ok, notification_group} <-
           notification_group
           |> NotificationGroup.changeset(attrs)
           |> Repo.update() do
      broadcast({:updated, notification_group})
      {:ok, notification_group}
    end
  end

  @doc """
  Deletes a notification group.

  ## Examples

      iex> delete_notification_group(notification_group)
      {:ok, %NotificationGroup{}}

      iex> delete_notification_group(notification_group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notification_group(%NotificationGroup{} = notification_group) do
    with {:ok, notification_group} <- Repo.delete(notification_group) do
      broadcast({:deleted, notification_group})
      {:ok, notification_group}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notification group changes.

  ## Examples

      iex> change_notification_group(notification_group)
      %Ecto.Changeset{data: %NotificationGroup{}}

  """
  def change_notification_group(%NotificationGroup{} = notification_group, attrs \\ %{}) do
    NotificationGroup.changeset(notification_group, attrs)
  end

  ## User Management

  @doc """
  Adds a user to a notification group.

  ## Examples

      iex> add_user_to_notification_group(notification_group, user)
      {:ok, %NotificationGroup{}}

  """
  def add_user_to_notification_group(%NotificationGroup{} = notification_group, %User{} = user) do
    notification_group = Repo.preload(notification_group, :users)

    with {:ok, notification_group} <-
           notification_group
           |> NotificationGroup.add_user_changeset(user)
           |> Repo.update() do
      broadcast({:user_added, notification_group, user})
      {:ok, notification_group}
    end
  end

  @doc """
  Removes a user from a notification group.

  ## Examples

      iex> remove_user_from_notification_group(notification_group, user)
      {:ok, %NotificationGroup{}}

  """
  def remove_user_from_notification_group(
        %NotificationGroup{} = notification_group,
        %User{} = user
      ) do
    notification_group = Repo.preload(notification_group, :users)

    with {:ok, notification_group} <-
           notification_group
           |> NotificationGroup.remove_user_changeset(user)
           |> Repo.update() do
      broadcast({:user_removed, notification_group, user})
      {:ok, notification_group}
    end
  end

  @doc """
  Updates all users in a notification group at once.

  ## Examples

      iex> update_notification_group_users(notification_group, [user1, user2])
      {:ok, %NotificationGroup{}}

  """
  def update_notification_group_users(%NotificationGroup{} = notification_group, users) do
    notification_group = Repo.preload(notification_group, :users)

    with {:ok, notification_group} <-
           notification_group
           |> NotificationGroup.users_changeset(users)
           |> Repo.update() do
      broadcast({:updated, notification_group})
      {:ok, notification_group}
    end
  end

  ## Query Functions

  @doc """
  Gets all notification groups that a user belongs to.

  ## Examples

      iex> list_user_notification_groups(user)
      [%NotificationGroup{}, ...]

  """
  def list_user_notification_groups(%User{id: user_id}) do
    from(ng in NotificationGroup,
      join: ngu in "notification_group_users",
      on: ngu.notification_group_id == ng.id,
      where: ngu.user_id == ^user_id,
      order_by: ng.name
    )
    |> Repo.all()
  end

  @doc """
  Gets all users that should be notified for a given alert description.

  Returns an empty list if no notification group is assigned.

  ## Examples

      iex> list_users_to_notify_for_alert(alert_description)
      [%User{}, ...]

  """
  def list_users_to_notify_for_alert(%AlertDescription{notification_group_id: nil}), do: []

  def list_users_to_notify_for_alert(%AlertDescription{notification_group_id: group_id}) do
    from(u in User,
      join: ngu in "notification_group_users",
      on: ngu.user_id == u.id,
      where: ngu.notification_group_id == type(^group_id, :binary_id),
      order_by: [u.email]
    )
    |> Repo.all()
  end

  @doc """
  Gets all alert descriptions that will notify a specific user.

  ## Examples

      iex> list_alert_descriptions_for_user(user)
      [%AlertDescription{}, ...]

  """
  def list_alert_descriptions_for_user(%User{id: user_id}) do
    from(ad in AlertDescription,
      join: ng in NotificationGroup,
      on: ad.notification_group_id == ng.id,
      join: ngu in "notification_group_users",
      on: ngu.notification_group_id == ng.id,
      where: ngu.user_id == ^user_id,
      preload: [:notification_group]
    )
    |> Repo.all()
  end
end
