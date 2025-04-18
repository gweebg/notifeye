defmodule Notifeye.AlertsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notifeye.Alerts` context.
  """

  @doc """
  Generate a alert.
  """
  def alert_fixture(attrs \\ %{}) do
    {:ok, alert} =
      attrs
      |> Enum.into(%{
        alert_id: "some alert_id",
        definition_id: "some definition_id",
        description: "some description",
        samples: "some samples",
        severity: "some severity",
        tags: "some tags",
        title: "some title"
      })
      |> Notifeye.Alerts.create_alert()

    alert
  end
end
