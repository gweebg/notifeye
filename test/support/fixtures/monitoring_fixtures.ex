defmodule Notifeye.MonitoringFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notifeye.Monitoring` context.
  """

  @doc """
  Generate a alert.
  """
  def alert_fixture(scope, attrs \\ %{}) do
    attrs = Enum.into(attrs, valid_alert_attrs())

    {:ok, alert} = Notifeye.Monitoring.create_alert(scope, attrs)
    alert
  end

  def valid_alert_attrs() do
    %{
      logz_id: System.unique_integer([:positive, :monotonic]),
      alert_title: "Mock Alert Title",
      alert_description: "This is a random alert description.",
      alert_severity: "high",
      alert_event_samples: "[{user: 'user'}]",
      alert_tags: ["insider", "login"],
      start: "1747064520000",
      end: "1747067000000"
    }
  end

  def invalid_alert_attrs do
    %{
      logz_id: -1,
      alert_title: nil
    }
  end
end
