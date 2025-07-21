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

  describe "acknowledge_assignment/2" do
    import Notifeye.AccountsFixtures
    import Notifeye.AlertAssignmentsFixtures
    import Notifeye.AlertDescriptionsFixtures
    import Notifeye.MonitoringFixtures

    alias Notifeye.Accounts.Scope
    alias Notifeye.Accounts

    defp create_assignment_with_alert(scope, alert_severity, inserted_at \\ nil) do
      alert = alert_fixture(scope, %{alert_severity: alert_severity})
      alert_description = alert_description_fixture()

      {:ok, assignment} =
        %{
          match: "match",
          status: :open,
          user_id: scope.user.id,
          alert_description_id: alert_description.id,
          alert_id: alert.id
        }
        |> AlertAssignments.create_alert_assignment()

      # force inserted_at if specified
      assignment =
        if inserted_at do
          assignment
          |> Ecto.Changeset.change(inserted_at: inserted_at)
          |> Notifeye.Repo.update!()
        else
          assignment
        end

      # return the assignment and preload the alert
      Notifeye.Repo.preload(assignment, [:alert])
    end

    test "acknowledges assignment within 24 hours, non-recurrent" do
      user = user_fixture_with_severity(%{}, 5)
      scope = Scope.for_user(user)
      assignment = create_assignment_with_alert(scope, "high")

      assert {:ok, new_standing, true} =
               AlertAssignments.acknowledge_assignment(scope, assignment)

      # standing should be restored (high severity -> 3 points)
      assert new_standing == 8
      assert Accounts.get_user!(user.id).standing == new_standing

      # assignment should be closed
      updated_assignment = AlertAssignments.get_alert_assignment!(assignment.id)
      assert updated_assignment.status == :closed
    end

    test "acknowledges assignment over 24 hours, non-recurrent" do
      user = user_fixture_with_severity(%{}, 8)
      scope = Scope.for_user(user)

      # make it 30 hours ago, won't restore standing
      delta =
        DateTime.utc_now()
        |> DateTime.add(-30, :hour)
        |> DateTime.truncate(:second)

      assignment = create_assignment_with_alert(scope, "medium", delta)

      assert {:ok, current_standing, false} =
               AlertAssignments.acknowledge_assignment(scope, assignment)

      # standing should be the same
      assert current_standing == 8
      assert Accounts.get_user!(user.id).standing == current_standing

      # assignment should be closed
      updated_assignment = AlertAssignments.get_alert_assignment!(assignment.id)
      assert updated_assignment.status == :closed
    end

    test "acknowledges assignment within 24 hours, recurrent" do
      user = user_fixture_with_severity(%{}, 5)
      scope = Scope.for_user(user)
      alert_description = alert_description_fixture()

      # create multiple assignmnets for the same alert description
      # this makes it recurrent
      for _i <- 1..3 do
        alert = alert_fixture(scope, %{alert_severity: "medium"})

        assignment_attrs = %{
          match: "test_user",
          status: :closed,
          user_id: user.id,
          alert_description_id: alert_description.id,
          alert_id: alert.id
        }

        {:ok, _} = AlertAssignments.create_alert_assignment(assignment_attrs)
      end

      # create the current alert (making it 4 within some seconds)
      alert = alert_fixture(scope, %{alert_severity: "medium"})

      current_assignment = %{
        match: "test_user",
        status: :open,
        user_id: user.id,
        alert_description_id: alert_description.id,
        alert_id: alert.id
      }

      {:ok, assignment} = AlertAssignments.create_alert_assignment(current_assignment)

      assert {:ok, current_standing, false} =
               AlertAssignments.acknowledge_assignment(scope, assignment)

      # standing should not be restored due to recurrence
      assert current_standing == 5
      assert Accounts.get_user!(user.id).standing == current_standing

      # assignment should be closed
      updated_assignment = AlertAssignments.get_alert_assignment!(assignment.id)
      assert updated_assignment.status == :closed
    end

    test "fails to acknowledge assignment that is not open" do
      user = user_fixture_with_severity(%{}, 5)
      scope = Scope.for_user(user)
      assignment = create_assignment_with_alert(scope, "high")

      # Close the assignment first
      {:ok, closed_assignment} =
        AlertAssignments.update_alert_assignment(assignment, %{status: :closed})

      assert {:error, error_message} =
               AlertAssignments.acknowledge_assignment(scope, closed_assignment)

      assert error_message =~ "cannot be acknowledged"
    end

    test "fails when user tries to acknowledge someone else's assignment" do
      user1 = user_fixture()
      scope1 = Scope.for_user(user1)

      user2 = user_fixture()
      scope2 = Scope.for_user(user2)

      # assignment belongs to user2
      assignment = create_assignment_with_alert(scope2, "medium")

      # should raise a MatchError due to the validation: scope.user.id == assignment.user_id
      assert_raise MatchError, fn ->
        AlertAssignments.acknowledge_assignment(scope1, assignment)
      end
    end
  end
end
