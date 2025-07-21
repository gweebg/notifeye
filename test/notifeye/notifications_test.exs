defmodule Notifeye.NotificationsTest do
  use Notifeye.DataCase

  alias Notifeye.Notifications
  alias Notifeye.AlertDescriptionsFixtures
  alias Notifeye.Notifications.NotificationGroup

  import Notifeye.AccountsFixtures
  import Notifeye.NotificationsFixtures
  import Notifeye.AlertDescriptionsFixtures

  describe "list_notification_groups/0" do
    test "returns all notification groups" do
      notification_group1 = notification_group_fixture()
      notification_group2 = notification_group_fixture()

      groups = Notifications.list_notification_groups()

      assert length(groups) == 2
      assert notification_group1 in groups
      assert notification_group2 in groups
    end

    test "returns empty list when no notification groups exist" do
      assert Notifications.list_notification_groups() == []
    end
  end

  describe "list_notification_groups_with_users/0" do
    test "returns notification groups with users preloaded" do
      user1 = user_fixture()
      user2 = user_fixture()
      notification_group = notification_group_fixture()

      {:ok, _updated_group} =
        Notifications.update_notification_group_users(notification_group, [user1, user2])

      [group] = Notifications.list_notification_groups_with_users()

      assert group.id == notification_group.id
      assert length(group.users) == 2
      assert Enum.any?(group.users, &(&1.id == user1.id))
      assert Enum.any?(group.users, &(&1.id == user2.id))
    end

    test "returns groups with empty users list when no users assigned" do
      notification_group = notification_group_fixture()

      [group] = Notifications.list_notification_groups_with_users()

      assert group.id == notification_group.id
      assert group.users == []
    end
  end

  describe "get_notification_group!/1" do
    test "returns the notification group with given id" do
      notification_group = notification_group_fixture()

      found_group = Notifications.get_notification_group!(notification_group.id)

      assert found_group.id == notification_group.id
      assert found_group.name == notification_group.name
    end

    test "raises when notification group does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Notifications.get_notification_group!(Ecto.UUID.generate())
      end
    end
  end

  describe "get_notification_group_with_users!/1" do
    test "returns notification group with users preloaded" do
      user1 = user_fixture()
      user2 = user_fixture()
      notification_group = notification_group_fixture()

      {:ok, _updated_group} =
        Notifications.update_notification_group_users(notification_group, [user1, user2])

      group = Notifications.get_notification_group_with_users!(notification_group.id)

      assert group.id == notification_group.id
      assert length(group.users) == 2
      assert Enum.any?(group.users, &(&1.id == user1.id))
      assert Enum.any?(group.users, &(&1.id == user2.id))
    end

    test "raises when notification group does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Notifications.get_notification_group_with_users!(Ecto.UUID.generate())
      end
    end
  end

  describe "create_notification_group/1" do
    test "with valid data creates a notification group" do
      valid_attrs = valid_notification_group_attributes()

      assert {:ok, %NotificationGroup{} = group} =
               Notifications.create_notification_group(valid_attrs)

      assert group.name == valid_attrs.name
      assert group.description == valid_attrs.description
    end

    test "with invalid data returns error changeset" do
      invalid_attrs = invalid_notification_group_attributes()

      assert {:error, %Ecto.Changeset{}} =
               Notifications.create_notification_group(invalid_attrs)
    end

    test "enforces unique constraint on name" do
      valid_attrs = valid_notification_group_attributes(%{name: "Unique Team"})

      assert {:ok, _group1} = Notifications.create_notification_group(valid_attrs)
      assert {:error, changeset} = Notifications.create_notification_group(valid_attrs)

      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "update_notification_group/2" do
    test "with valid data updates the notification group" do
      notification_group = notification_group_fixture()
      update_attrs = %{name: "Updated Team", description: "Updated description"}

      assert {:ok, %NotificationGroup{} = updated_group} =
               Notifications.update_notification_group(notification_group, update_attrs)

      assert updated_group.name == "Updated Team"
      assert updated_group.description == "Updated description"
      assert updated_group.id == notification_group.id
    end

    test "with invalid data returns error changeset" do
      notification_group = notification_group_fixture()
      invalid_attrs = %{name: ""}

      assert {:error, %Ecto.Changeset{}} =
               Notifications.update_notification_group(notification_group, invalid_attrs)

      # verify original data is unchanged
      unchanged_group = Notifications.get_notification_group!(notification_group.id)
      assert unchanged_group.name == notification_group.name
    end

    test "enforces unique constraint on name during update" do
      _group1 = notification_group_fixture(%{name: "Team 1"})
      group2 = notification_group_fixture(%{name: "Team 2"})

      assert {:error, changeset} =
               Notifications.update_notification_group(group2, %{name: "Team 1"})

      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "delete_notification_group/1" do
    test "deletes the notification group" do
      notification_group = notification_group_fixture()

      assert {:ok, %NotificationGroup{}} =
               Notifications.delete_notification_group(notification_group)

      assert_raise Ecto.NoResultsError, fn ->
        Notifications.get_notification_group!(notification_group.id)
      end
    end

    test "deletes notification group with users" do
      user1 = user_fixture()
      user2 = user_fixture()
      notification_group = notification_group_fixture()

      {:ok, group_with_users} =
        Notifications.update_notification_group_users(notification_group, [user1, user2])

      assert {:ok, %NotificationGroup{}} =
               Notifications.delete_notification_group(group_with_users)

      assert_raise Ecto.NoResultsError, fn ->
        Notifications.get_notification_group!(notification_group.id)
      end

      # verify users still exist (cascade delete should only affect join table)
      assert Notifeye.Accounts.get_user!(user1.id)
      assert Notifeye.Accounts.get_user!(user2.id)
    end
  end

  describe "change_notification_group/2" do
    test "returns a notification group changeset" do
      notification_group = notification_group_fixture()

      assert %Ecto.Changeset{} =
               Notifications.change_notification_group(notification_group)
    end

    test "returns changeset with given attributes" do
      notification_group = notification_group_fixture()
      attrs = %{name: "New Name"}

      changeset = Notifications.change_notification_group(notification_group, attrs)

      assert changeset.changes.name == "New Name"
    end
  end

  describe "add_user_to_notification_group/2" do
    test "adds user to notification group" do
      notification_group = notification_group_fixture()
      user = user_fixture()

      assert {:ok, %NotificationGroup{} = updated_group} =
               Notifications.add_user_to_notification_group(notification_group, user)

      group_with_users = Notifications.get_notification_group_with_users!(updated_group.id)
      assert length(group_with_users.users) == 1
      assert hd(group_with_users.users).id == user.id
    end

    test "returns error when user is already in notification group" do
      user = user_fixture()
      notification_group = notification_group_fixture()

      {:ok, _updated_group} =
        Notifications.add_user_to_notification_group(notification_group, user)

      assert {:error, changeset} =
               Notifications.add_user_to_notification_group(notification_group, user)

      assert %{users: ["user is already in this notification group"]} = errors_on(changeset)
    end
  end

  describe "remove_user_from_notification_group/2" do
    test "removes user from notification group" do
      user1 = user_fixture()
      user2 = user_fixture()
      notification_group = notification_group_fixture()

      {:ok, group_with_users} =
        Notifications.update_notification_group_users(notification_group, [user1, user2])

      assert {:ok, %NotificationGroup{}} =
               Notifications.remove_user_from_notification_group(group_with_users, user1)

      updated_group = Notifications.get_notification_group_with_users!(notification_group.id)
      assert length(updated_group.users) == 1
      assert hd(updated_group.users).id == user2.id
    end

    test "succeeds when user is not in notification group" do
      user1 = user_fixture()
      user2 = user_fixture()
      notification_group = notification_group_fixture()

      {:ok, group_with_users} =
        Notifications.update_notification_group_users(notification_group, [user1])

      assert {:ok, %NotificationGroup{}} =
               Notifications.remove_user_from_notification_group(group_with_users, user2)

      updated_group = Notifications.get_notification_group_with_users!(notification_group.id)
      assert length(updated_group.users) == 1
      assert hd(updated_group.users).id == user1.id
    end
  end

  describe "update_notification_group_users/2" do
    test "replaces all users in notification group" do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()
      notification_group = notification_group_fixture()

      # Start with user1 and user2
      {:ok, _group} =
        Notifications.update_notification_group_users(notification_group, [user1, user2])

      # Replace with only user3
      assert {:ok, %NotificationGroup{}} =
               Notifications.update_notification_group_users(notification_group, [user3])

      updated_group = Notifications.get_notification_group_with_users!(notification_group.id)
      assert length(updated_group.users) == 1
      assert hd(updated_group.users).id == user3.id
    end

    test "removes all users when given empty list" do
      user1 = user_fixture()
      user2 = user_fixture()
      notification_group = notification_group_fixture()

      {:ok, _group} =
        Notifications.update_notification_group_users(notification_group, [user1, user2])

      assert {:ok, %NotificationGroup{}} =
               Notifications.update_notification_group_users(notification_group, [])

      updated_group = Notifications.get_notification_group_with_users!(notification_group.id)
      assert updated_group.users == []
    end
  end

  describe "list_user_notification_groups/1" do
    test "returns notification groups that user belongs to" do
      user1 = user_fixture()
      user2 = user_fixture()

      group1 = notification_group_fixture(%{name: "Group 1"})
      group2 = notification_group_fixture(%{name: "Group 2"})
      _group3 = notification_group_fixture(%{name: "Group 3"})

      # Add user1 to group1 and group2
      {:ok, _} = Notifications.update_notification_group_users(group1, [user1])
      {:ok, _} = Notifications.update_notification_group_users(group2, [user1, user2])
      # group3 has no users

      user_groups = Notifications.list_user_notification_groups(user1)

      assert length(user_groups) == 2
      group_names = Enum.map(user_groups, & &1.name)
      assert "Group 1" in group_names
      assert "Group 2" in group_names
      refute "Group 3" in group_names
    end

    test "returns empty list when user belongs to no groups" do
      user = user_fixture()

      assert Notifications.list_user_notification_groups(user) == []
    end
  end

  describe "list_users_to_notify_for_alert/1" do
    test "returns users when alert description has notification group" do
      user1 = user_fixture()
      user2 = user_fixture()
      notification_group = notification_group_fixture()

      {:ok, _} = Notifications.update_notification_group_users(notification_group, [user1, user2])

      # mock an alert description with notification group
      alert_description =
        AlertDescriptionsFixtures.alert_description_with_notification_group_fixture(
          notification_group
        )

      users = Notifications.list_users_to_notify_for_alert(alert_description)

      assert length(users) == 2
      user_ids = Enum.map(users, & &1.id)
      assert user1.id in user_ids
      assert user2.id in user_ids
    end

    test "returns empty list when alert description has no notification group" do
      alert_description =
        AlertDescriptionsFixtures.alert_description_fixture()

      assert Notifications.list_users_to_notify_for_alert(alert_description) == []
    end

    test "returns empty list when notification group exists but has no users" do
      notification_group = notification_group_fixture()

      alert_description =
        AlertDescriptionsFixtures.alert_description_with_notification_group_fixture(
          notification_group
        )

      assert Notifications.list_users_to_notify_for_alert(alert_description) == []
    end
  end

  describe "list_alert_descriptions_for_user/1" do
    test "returns alert descriptions that will notify the user" do
      user1 = user_fixture()
      _user2 = user_fixture()

      notification_group = notification_group_fixture()
      {:ok, _} = Notifications.update_notification_group_users(notification_group, [user1])

      alert_description = alert_description_with_notification_group_fixture(notification_group)
      _alert_description_without_group = alert_description_fixture()

      alerts = Notifications.list_alert_descriptions_for_user(user1)

      assert length(alerts) == 1
      assert hd(alerts).id == alert_description.id
      assert hd(alerts).notification_group.id == notification_group.id
    end

    test "returns empty list when user belongs to no notification groups" do
      user = user_fixture()

      assert Notifications.list_alert_descriptions_for_user(user) == []
    end

    test "returns empty list when user's groups have no alert descriptions" do
      user = user_fixture()
      notification_group = notification_group_fixture()

      {:ok, _} = Notifications.update_notification_group_users(notification_group, [user])

      assert Notifications.list_alert_descriptions_for_user(user) == []
    end
  end
end
