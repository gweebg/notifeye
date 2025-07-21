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
        state: :enabled,
        pattern: "^.*user_id\:\w+$",
        verified: true
      })
      |> Notifeye.AlertDescriptions.create_alert_description()

    alert_description
  end

  @doc """
  Generate an alert_description with a notification group.
  """
  def alert_description_with_notification_group_fixture(notification_group, attrs \\ %{}) do
    attrs = Map.put(attrs, :notification_group_id, notification_group.id)
    alert_description_fixture(attrs)
  end
end
