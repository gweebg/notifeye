defmodule Notifeye.AlertAssignmentsTest do
  use Notifeye.DataCase

  alias Notifeye.AlertAssignments

  describe "alert_assignments" do
    alias Notifeye.AlertAssignments.AlertAssignment
    alias Notifeye.Accounts.User
    alias Notifeye.AlertDescriptions.AlertDescription

    import Notifeye.AlertAssignmentsFixtures

    @invalid_attrs %{match: nil, status: nil}

    test "list_alert_assignments/0 returns all alert_assignments" do
      alert_assignment = alert_assignment_fixture()
      assert AlertAssignments.list_alert_assignments() == [alert_assignment]
    end

    test "get_alert_assignment!/1 returns the alert_assignment with given id" do
      alert_assignment = alert_assignment_fixture()
      assert AlertAssignments.get_alert_assignment!(alert_assignment.id) == alert_assignment
    end

    test "create_alert_assignment/1 with valid data creates a alert_assignment" do
      %User{id: id} = Notifeye.AccountsFixtures.user_fixture()

      %AlertDescription{id: alert_description_id} =
        Notifeye.AlertDescriptionsFixtures.alert_description_fixture()

      valid_attrs = %{
        match: "some match",
        status: :unassigned,
        user_id: id,
        alert_description_id: alert_description_id
      }

      assert {:ok, %AlertAssignment{} = alert_assignment} =
               AlertAssignments.create_alert_assignment(valid_attrs)

      assert alert_assignment.match == "some match"
      assert alert_assignment.status == :unassigned
    end

    test "create_alert_assignment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               AlertAssignments.create_alert_assignment(@invalid_attrs)
    end

    test "update_alert_assignment/2 with valid data updates the alert_assignment" do
      alert_assignment = alert_assignment_fixture()
      update_attrs = %{match: "some updated match", status: :open}

      assert {:ok, %AlertAssignment{} = alert_assignment} =
               AlertAssignments.update_alert_assignment(alert_assignment, update_attrs)

      assert alert_assignment.match == "some updated match"
      assert alert_assignment.status == :open
    end

    test "update_alert_assignment/2 with invalid data returns error changeset" do
      alert_assignment = alert_assignment_fixture()

      assert {:error, %Ecto.Changeset{}} =
               AlertAssignments.update_alert_assignment(alert_assignment, @invalid_attrs)

      assert alert_assignment == AlertAssignments.get_alert_assignment!(alert_assignment.id)
    end

    test "delete_alert_assignment/1 deletes the alert_assignment" do
      alert_assignment = alert_assignment_fixture()

      assert {:ok, %AlertAssignment{}} =
               AlertAssignments.delete_alert_assignment(alert_assignment)

      assert_raise Ecto.NoResultsError, fn ->
        AlertAssignments.get_alert_assignment!(alert_assignment.id)
      end
    end

    test "change_alert_assignment/1 returns a alert_assignment changeset" do
      alert_assignment = alert_assignment_fixture()
      assert %Ecto.Changeset{} = AlertAssignments.change_alert_assignment(alert_assignment)
    end
  end
end
