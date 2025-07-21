defmodule Notifeye.AlertAssignmentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notifeye.AlertAssignments` context.
  """

  @doc """
  Generate a alert_assignment.
  """
  def alert_assignment_fixture(attrs \\ %{}) do
    user = Notifeye.AccountsFixtures.user_fixture()
    alert_description = Notifeye.AlertDescriptionsFixtures.alert_description_fixture()

    {:ok, alert_assignment} =
      attrs
      |> Enum.into(%{
        match: "some match",
        status: :unassigned,
        user_id: user.id,
        alert_description_id: alert_description.id
      })
      |> Notifeye.AlertAssignments.create_alert_assignment()

    alert_assignment
  end
end
