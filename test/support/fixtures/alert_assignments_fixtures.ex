defmodule Notifeye.AlertAssignmentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notifeye.AlertAssignments` context.
  """

  @doc """
  Generate a alert_assignment.
  """
  def alert_assignment_fixture(attrs \\ %{}) do
    {:ok, alert_assignment} =
      attrs
      |> Enum.into(%{
        match: "some match",
        status: :unassigned
      })
      |> Notifeye.AlertAssignments.create_alert_assignment()

    alert_assignment
  end
end
