defmodule Notifeye.AlertDescriptionsTest do
  use Notifeye.DataCase

  alias Notifeye.AlertDescriptions

  describe "alert_descriptions" do
    alias Notifeye.AlertDescriptions.AlertDescription

    import Notifeye.AlertDescriptionsFixtures

    @invalid_attrs %{enabled: nil, pattern: nil, verified: nil}

    test "list_alert_descriptions/0 returns all alert_descriptions" do
      alert_description = alert_description_fixture()
      assert AlertDescriptions.list_alert_descriptions() == [alert_description]
    end

    test "get_alert_description!/1 returns the alert_description with given id" do
      alert_description = alert_description_fixture()
      assert AlertDescriptions.get_alert_description!(alert_description.id) == alert_description
    end

    test "create_alert_description/1 with valid data creates a alert_description" do
      valid_attrs = %{enabled: true, pattern: "some pattern", verified: true}

      assert {:ok, %AlertDescription{} = alert_description} =
               AlertDescriptions.create_alert_description(valid_attrs)

      assert alert_description.enabled == true
      assert alert_description.pattern == "some pattern"
      assert alert_description.verified == true
    end

    test "create_alert_description/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               AlertDescriptions.create_alert_description(@invalid_attrs)
    end

    test "update_alert_description/2 with valid data updates the alert_description" do
      alert_description = alert_description_fixture()
      update_attrs = %{enabled: false, pattern: "some updated pattern", verified: false}

      assert {:ok, %AlertDescription{} = alert_description} =
               AlertDescriptions.update_alert_description(alert_description, update_attrs)

      assert alert_description.enabled == false
      assert alert_description.pattern == "some updated pattern"
      assert alert_description.verified == false
    end

    test "update_alert_description/2 with invalid data returns error changeset" do
      alert_description = alert_description_fixture()

      assert {:error, %Ecto.Changeset{}} =
               AlertDescriptions.update_alert_description(alert_description, @invalid_attrs)

      assert alert_description == AlertDescriptions.get_alert_description!(alert_description.id)
    end

    test "delete_alert_description/1 deletes the alert_description" do
      alert_description = alert_description_fixture()

      assert {:ok, %AlertDescription{}} =
               AlertDescriptions.delete_alert_description(alert_description)

      assert_raise Ecto.NoResultsError, fn ->
        AlertDescriptions.get_alert_description!(alert_description.id)
      end
    end

    test "change_alert_description/1 returns a alert_description changeset" do
      alert_description = alert_description_fixture()
      assert %Ecto.Changeset{} = AlertDescriptions.change_alert_description(alert_description)
    end
  end
end
