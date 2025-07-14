defmodule Notifeye.NotificationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notifeye.Notifications` context.
  """

  alias Notifeye.Notifications
  import Notifeye.AccountsFixtures

  @doc """
  Generate a notification group.
  """
  def notification_group_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Group #{System.unique_integer()}",
        description: "A test notification group."
      })

    {:ok, notification_group} = Notifications.create_notification_group(attrs)
    notification_group
  end

  @doc """
  Generate a notification group with users.
  """
  def notification_group_with_users_fixture(user_count \\ 2, attrs \\ %{}) do
    notification_group = notification_group_fixture(attrs)

    users = for _ <- 1..user_count, do: user_fixture()

    {:ok, notification_group} =
      Notifications.update_notification_group_users(notification_group, users)

    notification_group
  end

  @doc """
  Generate valid notification group attributes.
  """
  def valid_notification_group_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Group #{System.unique_integer()}",
      description: "A notification group for testing"
    })
  end

  @doc """
  Generate invalid notification group attributes.
  """
  def invalid_notification_group_attributes do
    %{
      name: nil,
      # exceeds max length
      description: String.duplicate("a", 501)
    }
  end
end
