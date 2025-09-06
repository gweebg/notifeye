defmodule Notifeye.Workers.ProcessorTest do
  use Notifeye.DataCase
  use Oban.Testing, repo: Notifeye.Repo

  import Notifeye.AccountsFixtures
  import Notifeye.MonitoringFixtures
  import Notifeye.AlertDescriptionsFixtures
  import Notifeye.NotificationsFixtures

  alias Notifeye.Workers.{Processor, Notifier}
  alias Notifeye.{AlertAssignments, Notifications}
  alias Notifeye.AlertAssignments.AlertAssignment
  alias Notifeye.Accounts

  @single_sample """
  The following have met the condition:
  [ {
    "host" : "user1",
  } ]
  """

  @multi_samples """
  The following have met the condition:
  [ {
    "host" : "user1",
  }, {
    "host" : "user2",
  }, {
    "host" : "user3",
  } ]
  """

  @standard_pattern "\"host\" : \"(?<user>[A-Za-z0-9\\-\\.]+)\""
  @non_matching_pattern ".*database.*"
  @invalid_pattern "["

  describe "perform/1" do
    test "creates new description if it doesn't exist" do
      logz_id = System.unique_integer([:positive])
      job = create_job(logz_id)

      # job returns the newly created alert description
      assert {:ok, alert_description} = Processor.perform(job)
      assert alert_description.id == logz_id
      assert alert_description.state == :disabled

      # and also enqueues a notification for the admin user to review the new
      # alert description
      assert_enqueued(worker: Notifier, args: %{description_id: logz_id})
    end

    test "returns :ok when alert description is disabled" do
      alert_description = alert_description_fixture(%{state: :disabled})
      job = create_job(alert_description.id)

      # job is cancelled with a message indicating the alert is disabled
      expected_message = "description #{alert_description.id} is disabled"
      assert {:ok, ^expected_message} = Processor.perform(job)

      # no notifications should be enqueued
      refute_enqueued(worker: Notifier)
    end

    test "cancels when pattern does not match any samples" do
      alert_description =
        alert_description_fixture(%{
          state: :enabled,
          pattern: @non_matching_pattern
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
          pattern: @invalid_pattern
        })

      job = create_job(alert_description.id)

      # job is cancelled with the error message from pattern matching
      # no notifications should be enqueued
      assert {:cancel, _reason} = Processor.perform(job)
      refute_enqueued(worker: Notifier)
    end

    test "returns the assignment and enqueues notification if samples match existing user" do
      user = user_fixture(%{email: "user1@example.com"})

      alert_description =
        alert_description_fixture(%{
          state: :enabled,
          pattern: @standard_pattern
        })

      job = create_job(alert_description.id)

      assert {:ok, [{:ok, %AlertAssignment{} = _assignment}]} = Processor.perform(job)

      # verify assignments were created in the database
      [%AlertAssignment{} = assignment] =
        AlertAssignments.list_alert_assignments_for_alert_description(alert_description.id)

      assert assignment.alert_description_id == alert_description.id
      assert assignment.user_id == user.id

      # should enqueue notification for the user
      assert_enqueued(worker: Notifier, args: %{assignment_id: assignment.id})
    end

    test "returns a list of assignments and enqueues many notifications if samples match multiple users" do
      _user = user_fixture(%{email: "user1@example.com"})
      _user = user_fixture(%{email: "user2@example.com"})
      _user = user_fixture(%{email: "user3@example.com"})

      description =
        alert_description_fixture(%{
          state: :enabled,
          pattern: @standard_pattern
        })

      job = create_job(description.id, @multi_samples)

      assert {:ok, _assignments} = Processor.perform(job)

      assignments =
        AlertAssignments.list_alert_assignments_for_alert_description(description.id)

      assert is_list(assignments) && length(assignments) == 3

      for assignment <- assignments do
        assert assignment.alert_description_id == description.id
        assert_enqueued(worker: Notifier, args: %{assignment_id: assignment.id})
      end
    end

    test "returns an admin assignment if the samples match but user doesn't exist" do
      {:ok, admin} = Accounts.create_admin_user(%{email: "admin@example.com"})

      description =
        alert_description_fixture(%{
          state: :enabled,
          pattern: @standard_pattern
        })

      job = create_job(description.id)

      {:ok, [{:ok, %AlertAssignment{}}]} = Processor.perform(job)

      [%AlertAssignment{} = assignment] =
        AlertAssignments.list_alert_assignments_for_alert_description(description.id)

      assert assignment.user_id == admin.id
      assert assignment.alert_description_id == description.id

      assert_enqueued(worker: Notifier, args: %{assignment_id: assignment.id})
    end

    test "enqueues group notifications if set in the description" do
      _user = user_fixture(%{email: "user1@example.com"})

      group_user1 = user_fixture(%{email: "group1@example.com"})
      group_user2 = user_fixture(%{email: "group2@example.com"})

      notification_group =
        create_notification_group_with_users([group_user1, group_user2])

      description =
        alert_description_fixture(%{
          state: :enabled,
          pattern: @standard_pattern,
          notification_group_id: notification_group.id
        })

      job = create_job(description.id)

      assert {:ok, [{:ok, %AlertAssignment{}}]} = Processor.perform(job)

      [%AlertAssignment{} = assignment] =
        AlertAssignments.list_alert_assignments_for_alert_description(description.id)

      # should enqueue assignment notification for the user
      assert_enqueued(worker: Notifier, args: %{assignment_id: assignment.id})

      # assert group notifications were enqueued
      for user <- notification_group.users do
        assert_enqueued(
          worker: Notifier,
          args: %{
            user_id: user.id,
            group_id: notification_group.id,
            assignment_id: assignment.id
          }
        )
      end
    end

    test "enqueues only group notifications if state is group_only" do
      user = user_fixture(%{email: "user1@example.com"})

      group_user1 = user_fixture(%{email: "group1@example.com"})
      group_user2 = user_fixture(%{email: "group2@example.com"})

      notification_group =
        create_notification_group_with_users([group_user1, group_user2])

      description =
        alert_description_fixture(%{
          state: :grouponly,
          pattern: @standard_pattern,
          notification_group_id: notification_group.id
        })

      job = create_job(description.id)

      assert {:ok, [{:ok, %AlertAssignment{}}]} = Processor.perform(job)

      [%AlertAssignment{} = assignment] =
        AlertAssignments.list_alert_assignments_for_alert_description(description.id)

      assert assignment.user_id == user.id
      assert assignment.alert_description_id == description.id

      all_jobs = all_enqueued(worker: Notifier)

      assert length(all_jobs) == 2

      # should enqueue group notifications for both users
      # must be tested like this because the assignment job
      # also matches the group notification job
      assert Enum.any?(all_jobs, fn job ->
               job.args == %{
                 "user_id" => group_user1.id,
                 "group_id" => notification_group.id,
                 "assignment_id" => assignment.id
               }
             end)

      # should not enqueue assignment notification for the user
      refute Enum.any?(all_jobs, fn job ->
               job.args == %{"assignment_id" => assignment.id}
             end)
    end

    test "enqueues assignment notifications and group notifications if group is set" do
      user = user_fixture(%{email: "user1@example.com"})

      group_user1 = user_fixture(%{email: "group1@example.com"})
      group_user2 = user_fixture(%{email: "group2@example.com"})

      notification_group =
        create_notification_group_with_users([group_user1, group_user2])

      description =
        alert_description_fixture(%{
          state: :enabled,
          pattern: @standard_pattern,
          notification_group_id: notification_group.id
        })

      job = create_job(description.id)

      assert {:ok, [{:ok, %AlertAssignment{}}]} = Processor.perform(job)

      [%AlertAssignment{} = assignment] =
        AlertAssignments.list_alert_assignments_for_alert_description(description.id)

      assert assignment.user_id == user.id
      assert assignment.alert_description_id == description.id

      all_jobs = all_enqueued(worker: Notifier)

      assert length(all_jobs) == 3

      assert Enum.any?(all_jobs, fn job ->
               job.args == %{
                 "user_id" => group_user1.id,
                 "group_id" => notification_group.id,
                 "assignment_id" => assignment.id
               }
             end)

      assert Enum.any?(all_jobs, fn job ->
               job.args == %{"assignment_id" => assignment.id}
             end)
    end
  end

  defp create_job(description_id, samples \\ @single_sample) do
    alert = alert_fixture(user_scope_fixture())

    %Oban.Job{
      args: %{
        "id" => alert.id,
        "logz_id" => description_id,
        "alert_event_samples" => samples
      }
    }
  end

  defp create_notification_group_with_users(users) do
    {:ok, notification_group} =
      notification_group_fixture()
      |> Notifications.update_notification_group_users(users)

    notification_group
  end
end
