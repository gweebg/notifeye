defmodule Notifeye.RulesApplyTest do
  use Notifeye.DataCase

  import Notifeye.AlertDescriptionsFixtures
  import Notifeye.RulesFixtures
  import Notifeye.MonitoringFixtures
  import Notifeye.AccountsFixtures

  alias Notifeye.Rules

  describe "check/2" do
    test "returns false when no active rule exists" do
      alert_description = alert_description_fixture()
      alert = alert_fixture(user_scope_fixture())

      assert Rules.check(alert_description.id, alert) == false
    end

    test "returns false when rule exists but is inactive" do
      alert_description = alert_description_fixture()

      alert =
        alert_fixture(
          user_scope_fixture(),
          %{title: "Alert #1"}
        )

      _rule =
        rule_fixture(%{
          alert_description_id: alert_description.id,
          rule_blocks: [single_clause_block("alert_title", "is", "Alert #1")]
        })

      assert Rules.check(alert_description.id, alert) == false
    end

    test "returns true for a single-clause rule" do
      alert_description = alert_description_fixture()

      alert =
        alert_fixture(
          user_scope_fixture(),
          %{alert_title: "Alert #1"}
        )

      _rule =
        rule_fixture(%{
          active: true,
          alert_description_id: alert_description.id,
          rule_blocks: [single_clause_block("alert_title", "starts_with", "Alert")]
        })

      assert Rules.check(alert_description.id, alert) == true
    end

    test "returns false for a single-clause rule" do
      alert_description = alert_description_fixture()

      alert =
        alert_fixture(
          user_scope_fixture(),
          %{alert_title: "Alert #1"}
        )

      _rule =
        rule_fixture(%{
          active: true,
          alert_description_id: alert_description.id,
          rule_blocks: [single_clause_block("alert_title", "matches", "Test.*1")]
        })

      assert Rules.check(alert_description.id, alert) == false
    end

    test "returns true for a multi-clause rule" do
      alert_description = alert_description_fixture()

      alert =
        alert_fixture(
          user_scope_fixture(),
          %{
            alert_title: "Alert #1",
            alert_severity: "medium",
            alert_description: "Some Error Occured!"
          }
        )

      _rule =
        rule_fixture(%{
          active: true,
          alert_description_id: alert_description.id,
          rule_blocks: [
            %{
              clauses: [
                %{field: "alert_title", operator: "is", value: "Alert #1"},
                %{field: "alert_severity", operator: "is_not", value: "high"},
                %{field: "alert_description", operator: "matches", value: "error"}
              ]
            }
          ]
        })

      assert Rules.check(alert_description.id, alert) == true
    end

    test "returns false for a multi-clause rule (at least one clause fails)" do
      alert_description = alert_description_fixture()

      alert =
        alert_fixture(
          user_scope_fixture(),
          %{
            alert_title: "Alert #1",
            alert_severity: "low",
            alert_description: "Database error occurred"
          }
        )

      _rule =
        rule_fixture(%{
          active: true,
          alert_description_id: alert_description.id,
          rule_blocks: [
            %{
              clauses: [
                %{field: "alert_title", operator: "starts_with", value: "Not an Alert"},
                %{field: "alert_severity", operator: "is", value: "low"},
                %{field: "alert_description", operator: "matches", value: "error"}
              ]
            }
          ]
        })

      assert Rules.check(alert_description.id, alert) == false
    end

    test "returns true for a multi-block rule (full-match)" do
      alert_description = alert_description_fixture()

      alert =
        alert_fixture(
          user_scope_fixture(),
          %{
            alert_title: "Alert #1",
            alert_severity: "high"
          }
        )

      _rule =
        rule_fixture(%{
          alert_description_id: alert_description.id,
          active: true,
          rule_blocks: [
            single_clause_block("alert_title", "is", "Alert #1"),
            single_clause_block("alert_severity", "is_not", "low")
          ]
        })

      assert Rules.check(alert_description.id, alert) == true
    end

    test "returns true for a multi-block rule (partial-match)" do
      alert_description = alert_description_fixture()

      alert =
        alert_fixture(
          user_scope_fixture(),
          %{
            alert_severity: "high",
            alert_description: "Database error occurred"
          }
        )

      _rule =
        rule_fixture(%{
          alert_description_id: alert_description.id,
          active: true,
          rule_blocks: [
            single_clause_block("alert_description", "contains", "error"),
            single_clause_block("alert_severity", "is", "low")
          ]
        })

      assert Rules.check(alert_description.id, alert) == true
    end

    test "returns false for a multi-block rule (none-match)" do
      alert_description = alert_description_fixture()

      alert =
        alert_fixture(
          user_scope_fixture(),
          %{
            alert_title: "Alert #1",
            alert_tags: ["tag_a", "tag_b"]
          }
        )

      _rule =
        rule_fixture(%{
          alert_description_id: alert_description.id,
          active: true,
          rule_blocks: [
            single_clause_block("alert_title", "is", "Different Alert"),
            single_clause_block("alert_tags", "exclude", "tag_a")
          ]
        })

      assert Rules.check(alert_description.id, alert) == false
    end

    test "checks for a multi-block multi-clause rule" do
      alert_description = alert_description_fixture()

      _rule =
        rule_fixture(%{
          alert_description_id: alert_description.id,
          active: true,
          rule_blocks: [
            %{
              clauses: [
                %{field: "alert_title", operator: "is", value: "Alert #1"},
                %{field: "alert_severity", operator: "is_not", value: "low"}
              ]
            },
            %{
              clauses: [
                %{field: "alert_description", operator: "matches", value: "database"},
                %{field: "alert_severity", operator: "is", value: "low"}
              ]
            },
            single_clause_block("alert_title", "matches", "emergency")
          ]
        })

      alert1 =
        alert_fixture(user_scope_fixture(), %{
          alert_title: "Alert #1",
          alert_severity: "high"
        })

      assert Rules.check(alert_description.id, alert1) == true

      alert2 =
        alert_fixture(user_scope_fixture(), %{
          alert_title: "Emergency Alert"
        })

      assert Rules.check(alert_description.id, alert2) == true

      alert3 =
        alert_fixture(user_scope_fixture(), %{
          alert_title: "Alert #2",
          alert_description: "Normal operation.",
          alert_severity: "low"
        })

      assert Rules.check(alert_description.id, alert3) == false

      alert4 =
        alert_fixture(user_scope_fixture(), %{
          alert_title: "Alert #1",
          alert_severity: "low"
        })

      assert Rules.check(alert_description.id, alert4) == false
    end

    test "checks datetime and time operators agains a complex rule" do
      alert_description = alert_description_fixture()

      _rule =
        rule_fixture(%{
          alert_description_id: alert_description.id,
          active: true,
          rule_blocks: [
            %{
              clauses: [
                %{field: "start", operator: "after_time", value: "09:00:00"},
                %{field: "end", operator: "before_time", value: "10:00:00"}
              ]
            }
          ]
        })

      # should pass first block
      alert1 =
        alert_fixture(
          user_scope_fixture(),
          %{
            # 09:30:00
            start: "1754818200000",
            # 09:55:15
            end: "1754819715000"
          }
        )

      assert Rules.check(alert_description.id, alert1) == true

      # should fail first block
      alert2 =
        alert_fixture(
          user_scope_fixture(),
          %{
            # 12:55:00
            start: "1754830515000",
            # 13:00:00
            end: "1754834400000"
          }
        )

      assert Rules.check(alert_description.id, alert2) == false
    end
  end
end
