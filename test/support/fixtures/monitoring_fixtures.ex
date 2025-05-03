defmodule Notifeye.MonitoringFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notifeye.Monitoring` context.
  """

  @doc """
  Generate a alert.
  """
  def alert_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        alert_description: "some alert_description",
        alert_event_samples: "some alert_event_samples",
        alert_severity: "some alert_severity",
        alert_tags: ["option1", "option2"],
        alert_title: "some alert_title",
        end: ~U[2025-05-02 15:02:00Z],
        logz_id: "some logz_id",
        start: ~U[2025-05-02 15:02:00Z]
      })

    {:ok, alert} = Notifeye.Monitoring.create_alert(scope, attrs)
    alert
  end
end
