defmodule Notifeye.AlertDescriptionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Notifeye.AlertDescriptions` context.
  """

  @doc """
  Generate a alert_description.
  """
  def alert_description_fixture(attrs \\ %{}) do
    scope = Notifeye.AccountsFixtures.user_scope_fixture()
    alert = Notifeye.MonitoringFixtures.alert_fixture(scope)

    {:ok, alert_description} =
      attrs
      |> Enum.into(%{
        id: alert.logz_id,
        pattern: "^.*user_id\:\w+$",
        verified: true
      })
      |> Notifeye.AlertDescriptions.create_alert_description()

    alert_description
  end
end
