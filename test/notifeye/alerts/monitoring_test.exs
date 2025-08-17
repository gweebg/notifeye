defmodule Notifeye.MonitoringTest do
  use Notifeye.DataCase

  import Notifeye.MonitoringFixtures
  import Notifeye.AccountsFixtures, only: [user_scope_fixture: 0]

  alias Notifeye.Monitoring
  alias Notifeye.Monitoring.Alert

  describe "create_alert/2" do
    test "with valid data creates an alert" do
      attrs = valid_alert_attrs()
      scope = user_scope_fixture()

      assert {:ok, %Alert{} = alert} = Monitoring.create_alert(scope, attrs)

      assert alert.user_id == scope.user.id
      assert alert.logz_id == attrs.logz_id
      assert alert.alert_title == attrs.alert_title
      assert alert.alert_description == attrs.alert_description
      assert alert.alert_severity == attrs.alert_severity
      assert alert.alert_event_samples == attrs.alert_event_samples
      assert alert.alert_tags == attrs.alert_tags
      assert alert.start == ~U[2025-05-12 15:42:00Z]
      assert alert.end == ~U[2025-05-12 16:23:20Z]
    end

    test "with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Monitoring.create_alert(scope, invalid_alert_attrs())
    end

    test "with valid data normalizes the severity to lowercase" do
      attrs = Enum.into(%{alert_severity: "High"}, valid_alert_attrs())
      scope = user_scope_fixture()

      assert {:ok, %Alert{} = alert} = Monitoring.create_alert(scope, attrs)
      assert alert.alert_severity == String.downcase(attrs.alert_severity)
    end
  end

  test "get_alert!/1" do
    scope = user_scope_fixture()
    alert = alert_fixture(scope)

    assert %Alert{} = a = Monitoring.get_alert!(scope, alert.id)
    assert a.id == alert.id
  end
end
