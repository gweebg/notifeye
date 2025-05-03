defmodule Notifeye.MonitoringTest do
  use Notifeye.DataCase

  alias Notifeye.Monitoring

  describe "alerts" do
    alias Notifeye.Monitoring.Alert

    import Notifeye.AccountsFixtures, only: [user_scope_fixture: 0]

    @invalid_attrs %{
      start: nil,
      end: nil,
      logz_id: nil,
      alert_title: nil,
      alert_description: nil,
      alert_severity: nil,
      alert_event_samples: nil,
      alert_tags: nil
    }

    test "create_alert/2 with valid data creates a alert" do
      valid_attrs = %{
        start: ~U[2025-05-02 15:02:00Z],
        end: ~U[2025-05-02 15:02:00Z],
        logz_id: "some logz_id",
        alert_title: "some alert_title",
        alert_description: "some alert_description",
        alert_severity: "some alert_severity",
        alert_event_samples: "some alert_event_samples",
        alert_tags: ["option1", "option2"]
      }

      scope = user_scope_fixture()

      assert {:ok, %Alert{} = alert} = Monitoring.create_alert(scope, valid_attrs)
      assert alert.start == ~U[2025-05-02 15:02:00Z]
      assert alert.end == ~U[2025-05-02 15:02:00Z]
      assert alert.logz_id == "some logz_id"
      assert alert.alert_title == "some alert_title"
      assert alert.alert_description == "some alert_description"
      assert alert.alert_severity == "some alert_severity"
      assert alert.alert_event_samples == "some alert_event_samples"
      assert alert.alert_tags == ["option1", "option2"]
      assert alert.user_id == scope.user.id
    end

    test "create_alert/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Monitoring.create_alert(scope, @invalid_attrs)
    end
  end
end
