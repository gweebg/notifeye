defmodule Notifeye.AlertsTest do
  use Notifeye.DataCase

  alias Notifeye.Alerts

  describe "alerts" do
    alias Notifeye.Alerts.Alert

    import Notifeye.AlertsFixtures

    @invalid_attrs %{
      alert_id: nil,
      description: nil,
      title: nil,
      severity: nil,
      definition_id: nil,
      tags: nil,
      samples: nil
    }

    test "list_alerts/0 returns all alerts" do
      alert = alert_fixture()
      assert Alerts.list_alerts() == [alert]
    end

    test "get_alert!/1 returns the alert with given id" do
      alert = alert_fixture()
      assert Alerts.get_alert!(alert.id) == alert
    end

    test "create_alert/1 with valid data creates a alert" do
      valid_attrs = %{
        alert_id: "some alert_id",
        description: "some description",
        title: "some title",
        severity: "some severity",
        definition_id: "some definition_id",
        tags: "some tags",
        samples: "some samples"
      }

      assert {:ok, %Alert{} = alert} = Alerts.create_alert(valid_attrs)
      assert alert.alert_id == "some alert_id"
      assert alert.description == "some description"
      assert alert.title == "some title"
      assert alert.severity == "some severity"
      assert alert.definition_id == "some definition_id"
      assert alert.tags == "some tags"
      assert alert.samples == "some samples"
    end

    test "create_alert/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Alerts.create_alert(@invalid_attrs)
    end

    test "update_alert/2 with valid data updates the alert" do
      alert = alert_fixture()

      update_attrs = %{
        alert_id: "some updated alert_id",
        description: "some updated description",
        title: "some updated title",
        severity: "some updated severity",
        definition_id: "some updated definition_id",
        tags: "some updated tags",
        samples: "some updated samples"
      }

      assert {:ok, %Alert{} = alert} = Alerts.update_alert(alert, update_attrs)
      assert alert.alert_id == "some updated alert_id"
      assert alert.description == "some updated description"
      assert alert.title == "some updated title"
      assert alert.severity == "some updated severity"
      assert alert.definition_id == "some updated definition_id"
      assert alert.tags == "some updated tags"
      assert alert.samples == "some updated samples"
    end

    test "update_alert/2 with invalid data returns error changeset" do
      alert = alert_fixture()
      assert {:error, %Ecto.Changeset{}} = Alerts.update_alert(alert, @invalid_attrs)
      assert alert == Alerts.get_alert!(alert.id)
    end

    test "delete_alert/1 deletes the alert" do
      alert = alert_fixture()
      assert {:ok, %Alert{}} = Alerts.delete_alert(alert)
      assert_raise Ecto.NoResultsError, fn -> Alerts.get_alert!(alert.id) end
    end

    test "change_alert/1 returns a alert changeset" do
      alert = alert_fixture()
      assert %Ecto.Changeset{} = Alerts.change_alert(alert)
    end
  end
end
