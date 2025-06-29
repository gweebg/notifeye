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
      scope = Notifeye.AccountsFixtures.user_scope_fixture()
      alert = Notifeye.MonitoringFixtures.alert_fixture(scope)

      valid_attrs = %{id: alert.logz_id, enabled: true, pattern: "some pattern", verified: true}

      assert {:ok, %AlertDescription{} = alert_description} =
               AlertDescriptions.create_alert_description(valid_attrs)

      assert alert_description.id == alert.logz_id
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

    test "maybe_match_samples/2 returns nil if the pattern does not match any part of the samples" do
      pattern = "\"dvchost\" : \"(?<user>[A-Za-z0-9\-\.]+)\""

      samples =
        "[ {\n  \"dvchost\" : \"this wont match\",\n  \"dvc\" : \"10.10.10.10\",\n \"count\" : 1.0\n} ]"

      assert AlertDescriptions.maybe_match_samples(pattern, samples) == nil
    end

    test "maybe_match_samples/2 returns a match from the samples" do
      pattern = "\"dvchost\" : \"(?<user>[A-Za-z0-9\-\.]+)\""

      samples =
        "[ {\n  \"dvchost\" : \"this-will-match.109\",\n  \"dvc\" : \"10.10.10.10\",\n \"count\" : 1.0\n} ]"

      assert AlertDescriptions.maybe_match_samples(pattern, samples) ==
               "this-will-match.109"
    end

    test "maybe_match_samples/2 returns error due to bad regex expression" do
      pattern = "\"dvchost\" : \"(?<user>[\w\d\-\.]+)\""

      samples =
        "[ {\n  \"dvchost\" : \"doesnt matter\",\n  \"dvc\" : \"10.10.10.10\",\n \"count\" : 1.0\n} ]"

      assert {:error, _reason} = AlertDescriptions.maybe_match_samples(pattern, samples)
    end

    test "maybe_match_samples/2 returns error due to no named capture group 'user'" do
      pattern = "\"dvchost\" : \"([A-Za-z0-9\-\.]+)\""

      samples =
        "[ {\n  \"dvchost\" : \"this-matches-but-no-group\",\n  \"dvc\" : \"10.10.10.10\",\n \"count\" : 1.0\n} ]"

      assert {:error, "named capture 'user' is mandatory in the pattern"} =
               AlertDescriptions.maybe_match_samples(pattern, samples)
    end
  end
end
