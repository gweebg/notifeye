defmodule Notifeye.Notifications.MessageBuilder do
  @moduledoc """
  Module for building `%Message{}` structs from arguments
  passed onto an Oban `perform/1` job.
  """

  alias Notifeye.{Accounts, AlertAssignments, AlertDescriptions, Notifications}
  alias Notifeye.Notifications.Message

  def from_args(%{"description_id" => id}) do
    user = Accounts.get_admin_user!()
    desc = AlertDescriptions.get_alert_description!(id)

    %Message{
      type: :description_created,
      data: %{description: desc},
      to: user
    }
  end

  def from_args(%{"user_id" => user_id, "group_id" => group_id, "assignment_id" => assignment_id}) do
    user = Accounts.get_user!(user_id)

    assignment =
      AlertAssignments.get_alert_assignment!(assignment_id, [:alert, :user, :alert_description])

    group = Notifications.get_notification_group!(group_id)

    %Message{
      type: :group_notification,
      data: %{group: group, assignment: assignment},
      to: user,
      metadata: %{rule: true}
    }
  end

  def from_args(%{"lead_id" => lead_id, "assignment_id" => assignment_id}) do
    assignment =
      AlertAssignments.get_alert_assignment!(
        assignment_id,
        [:alert, :user, :alert_description]
      )

    %Message{
      type: :lead_notification,
      data: %{assignment: assignment},
      to: Accounts.get_user!(lead_id),
      metadata: %{rule: true}
    }
  end

  def from_args(%{"assignment_id" => assignment_id}) do
    assignment =
      AlertAssignments.get_alert_assignment!(
        assignment_id,
        [:alert, :user, :alert_description]
      )

    %Message{
      type: :assignment_created,
      data: %{assignment: assignment},
      to: Accounts.get_user!(assignment.user.id),
      metadata: %{rule: true}
    }
  end
end
