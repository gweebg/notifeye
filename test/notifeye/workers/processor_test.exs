defmodule Notifeye.Workers.ProcessorTest do
  use Notifeye.DataCase
  use Oban.Testing, repo: Notifeye.Repo

  import Notifeye.AccountsFixtures
  import Notifeye.AlertDescriptionsFixtures
  import Notifeye.NotificationsFixtures

  alias Notifeye.Workers.{Processor, Notifier}
  alias Notifeye.{AlertAssignments, Notifications}
  alias Notifeye.AlertAssignments.AlertAssignment

  @single_sample """
  The following have met the condition:
  [ {
    "dvchost" : "user1",
    "dvc" : "10.10.60.223",
    "darktraceUrl" : "",
    "count" : 1.0
  } ]
  """

  @multi_samples """
  The following have met the condition:
  [ {
    "dvchost" : "user1",
    "dvc" : "10.10.60.185",
    "darktraceUrl" : "",
    "count" : 1.0
  }, {
    "dvchost" : "user2",
    "dvc" : "10.10.60.185",
    "darktraceUrl" : "",
    "count" : 1.0
  }, {
    "dvchost" : "user3",
    "dvc" : "10.10.60.229",
    "darktraceUrl" : "",
    "count" : 1.0
  } ]
  """

  # helper functions to reduce duplication
  defp standard_pattern, do: "\"dvchost\" : \"(?<user>[A-Za-z0-9\\-\\.]+)\""
  defp non_matching_pattern, do: ".*database.*"
  defp invalid_pattern, do: "["

  defp create_job(logz_id, samples \\ @single_sample) do
    %Oban.Job{
      args: %{"logz_id" => logz_id, "alert_event_samples" => samples}
    }
  end

  defp create_notification_group_with_users(users) do
    {:ok, notification_group} =
      notification_group_fixture()
      |> Notifications.update_notification_group_users(users)

    notification_group
  end

  describe "perform/1" do
    test "creates new alert description when logz_id does not exist" do
      logz_id = System.unique_integer([:positive])
      job = create_job(logz_id)

      # job returns the newly created alert description
      assert {:ok, alert_description} = Processor.perform(job)
      assert alert_description.id == logz_id
      assert alert_description.state == :disabled

      # and also enqueues a notification for the admin user to review the new
      # alert description
      assert_enqueued(worker: Notifier, args: %{alert_description_id: logz_id})
    end

    test "cancels when alert description is disabled" do
      alert_description = alert_description_fixture(%{state: :disabled})
      job = create_job(alert_description.id)

      # job is cancelled with a message indicating the alert is disabled
      expected_message = "alert (#{alert_description.id}) is disabled"
      assert {:cancel, ^expected_message} = Processor.perform(job)

      # no notifications should be enqueued
      refute_enqueued(worker: Notifier)
    end

    test "cancels when pattern does not match samples" do
      alert_description =
        alert_description_fixture(%{
          state: :enabled,
          pattern: non_matching_pattern()
        })

      job = create_job(alert_description.id)

      expected_message =
        "pattern #{alert_description.pattern} does not match any part of the alert samples"

      # job is cancelled with a message indicating no matches
      # no notifications should be enqueued
      assert {:cancel, ^expected_message} = Processor.perform(job)
      refute_enqueued(worker: Notifier)
    end

    test "cancels when pattern matching returns an error" do
      alert_description =
        alert_description_fixture(%{
          state: :enabled,
          pattern: invalid_pattern()
        })

      job = create_job(alert_description.id)

      # job is cancelled with the error message from pattern matching
      # no notifications should be enqueued
      assert {:cancel, _error_message} = Processor.perform(job)
      refute_enqueued(worker: Notifier)
    end

    test "processes enabled alert with matching pattern for an existing user - no notification group" do
      user1 = user_fixture(%{email: "user1@example.com"})

      alert_description =
        alert_description_fixture(%{
          state: :enabled,
          pattern: standard_pattern()
        })

      job = create_job(alert_description.id)

      assert {:ok, [%AlertAssignment{} = assignment]} = Processor.perform(job)

      # verify assignments were created in the database
      db_assignments =
        AlertAssignments.list_alert_assignments_for_alert_description(alert_description.id)

      assert length(db_assignments) == 1

      # should enqueue notification for the user
      assert_enqueued(worker: Notifier, args: %{assignment_id: assignment.id})

      # should not enqueue group notifications (no notification group)
      refute_enqueued(
        worker: Notifier,
        args: %{user_id: user1.id, alert_description_id: alert_description.id}
      )
    end

    test "processes enabled alert with notification group" do
      _user1 = user_fixture(%{email: "user1@example.com"})
      group_user1 = user_fixture(%{email: "group1@example.com"})
      group_user2 = user_fixture(%{email: "group2@example.com"})

      notification_group =
        create_notification_group_with_users([group_user1, group_user2])

      alert_description =
        alert_description_fixture(%{
          state: :enabled,
          pattern: standard_pattern(),
          notification_group_id: notification_group.id
        })

      job = create_job(alert_description.id)

      assert {:ok, [%AlertAssignment{} = assignment]} = Processor.perform(job)

      # should enqueue assignment notification for the user
      assert_enqueued(worker: Notifier, args: %{assignment_id: assignment.id})

      # should enqueue group notifications
      assert_enqueued(
        worker: Notifier,
        args: %{
          user_id: group_user1.id,
          alert_description_id: alert_description.id,
          assignment_id: assignment.id
        }
      )

      assert_enqueued(
        worker: Notifier,
        args: %{
          user_id: group_user2.id,
          alert_description_id: alert_description.id,
          assignment_id: assignment.id
        }
      )
    end

    test "processes grouponly alert with notification group, only sending group notifications" do
      _user1 = user_fixture(%{email: "user1@example.com"})
      group_user1 = user_fixture(%{email: "group1@example.com"})
      group_user2 = user_fixture(%{email: "group2@example.com"})

      notification_group =
        create_notification_group_with_users([group_user1, group_user2])

      alert_description =
        alert_description_fixture(%{
          state: :grouponly,
          pattern: standard_pattern(),
          notification_group_id: notification_group.id
        })

      job = create_job(alert_description.id)

      assert {:ok, [%AlertAssignment{} = assignment]} = Processor.perform(job)

      jobs = all_enqueued(worker: Notifier)

      # should enqueue group notifications for both users
      # must be tested like this because the assignment job
      # also matches the group notification job
      assert Enum.any?(jobs, fn job ->
               job.args == %{
                 "user_id" => group_user1.id,
                 "alert_description_id" => alert_description.id,
                 "assignment_id" => assignment.id
               }
             end)

      # should not enqueue assignment notification for the user
      refute Enum.any?(jobs, fn job ->
               job.args == %{"assignment_id" => assignment.id}
             end)
    end

    test "processes grouponly alert without notification group - creates assignments but no notifications" do
      _user1 = user_fixture(%{email: "user1@example.com"})

      alert_description =
        alert_description_fixture(%{
          state: :grouponly,
          pattern: standard_pattern()
        })

      job = create_job(alert_description.id)

      assert {:ok, assignments} = Processor.perform(job)
      assert length(assignments) == 1

      # should create alert assignments
      db_assignments =
        AlertAssignments.list_alert_assignments_for_alert_description(alert_description.id)

      assert length(db_assignments) == 1

      # should not enqueue any notifications
      refute_enqueued(worker: Notifier)
    end

    test "processes alert with multiple matches - creating multiple assignments and notifications" do
      _user1 = user_fixture(%{email: "user1@example.com"})
      _user2 = user_fixture(%{email: "user2@example.com"})
      _user3 = user_fixture(%{email: "user3@example.com"})

      alert_description =
        alert_description_fixture(%{
          state: :enabled,
          pattern: standard_pattern()
        })

      job = create_job(alert_description.id, @multi_samples)

      # ensure 3 assignments were returned
      assert {:ok, assignments} = Processor.perform(job)
      assert length(assignments) == 3

      # verify 3 assignments were created in the database
      db_assignments =
        AlertAssignments.list_alert_assignments_for_alert_description(alert_description.id)

      assert length(db_assignments) == 3

      # should enqueue 3 notification jobs, one for each assignment
      for assignment <- assignments do
        assert_enqueued(worker: Notifier, args: %{assignment_id: assignment.id})
      end
    end
  end
end
