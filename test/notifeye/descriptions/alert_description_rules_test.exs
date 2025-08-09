defmodule Notifeye.AlertDescriptionsRulesTest do
  use Notifeye.DataCase

  alias Notifeye.Rules
  alias Notifeye.AlertDescriptions.AlertDescription.Rule
  alias Notifeye.AlertDescriptionsFixtures

  describe "get_rule/1" do
    test "returns rule when it exists" do
      rule = rule_fixture()
      assert Rules.get_rule(rule.id) == rule
    end

    test "returns nil when rule does not exist" do
      assert Rules.get_rule(-1) == nil
    end
  end

  describe "get_rule!/1" do
    test "returns rule when it exists" do
      rule = rule_fixture()
      assert Rules.get_rule!(rule.id) == rule
    end

    test "raises when rule does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Rules.get_rule!(-1)
      end
    end
  end

  describe "get_active_rule/1" do
    test "returns the active rule for an alert description" do
      alert_description = AlertDescriptionsFixtures.alert_description_fixture()

      rule = rule_fixture(%{alert_description_id: alert_description.id, active: true})
      _inactive_rule = rule_fixture(%{alert_description_id: alert_description.id})

      assert Rules.get_active_rule(alert_description.id) == rule
    end

    test "returns nil if not rule is active" do
      alert_description = AlertDescriptionsFixtures.alert_description_fixture()
      _inactive_rule = rule_fixture(%{alert_description_id: alert_description.id, active: false})

      assert nil == Rules.get_active_rule(alert_description.id)
    end
  end

  describe "list_rules/1" do
    test "returns all rules for an alert description" do
      alert_description = AlertDescriptionsFixtures.alert_description_fixture()
      rule1 = rule_fixture(%{alert_description_id: alert_description.id, name: "Rule 1"})
      rule2 = rule_fixture(%{alert_description_id: alert_description.id, name: "Rule 2"})

      rules = Rules.list_rules(alert_description.id)
      assert length(rules) == 2
      assert rule1 in rules
      assert rule2 in rules
    end

    test "returns empty list when no rules exist" do
      alert_description = AlertDescriptionsFixtures.alert_description_fixture()
      assert Rules.list_rules(alert_description.id) == []
    end

    test "does not return rules from other alert descriptions" do
      alert_description1 = AlertDescriptionsFixtures.alert_description_fixture()
      alert_description2 = AlertDescriptionsFixtures.alert_description_fixture()

      rule1 = rule_fixture(%{alert_description_id: alert_description1.id})
      _rule2 = rule_fixture(%{alert_description_id: alert_description2.id})

      rules = Rules.list_rules(alert_description1.id)
      assert length(rules) == 1
      assert hd(rules).id == rule1.id
    end
  end

  describe "create_rule/1" do
    test "creates rule with valid data" do
      alert_description = AlertDescriptionsFixtures.alert_description_fixture()

      valid_attrs = %{
        name: "Test Rule",
        action: :notify,
        action_value: "email",
        alert_description_id: alert_description.id,
        rule_blocks: [
          %{
            clauses: [
              %{field: "alert_title", operator: "is", value: "Test Alert"},
              %{field: "alert_tags", operator: "include", value: "test"}
            ]
          },
          %{
            clauses: [%{field: "alert_title", operator: "is", value: "Test Alert"}]
          }
        ]
      }

      assert {:ok, %Rule{} = rule} = Rules.create_rule(valid_attrs)
      assert rule.name == "Test Rule"
      assert rule.action == :notify
      assert rule.action_value == "email"
      # defaults to false
      assert rule.active == false
      # defaults to 0
      assert rule.count == 0
      assert length(rule.rule_blocks) == 2
    end

    test "strips active field from attrs" do
      alert_description = AlertDescriptionsFixtures.alert_description_fixture()

      attrs_with_active = %{
        name: "Test Rule",
        action: :notify,
        alert_description_id: alert_description.id,
        # this should be ignored
        active: true,
        rule_blocks: [
          %{
            clauses: [
              %{field: "alert_title", operator: "is", value: "Test Alert"}
            ]
          }
        ]
      }

      assert {:ok, %Rule{} = rule} = Rules.create_rule(attrs_with_active)
      # should be false despite attrs having active: true
      assert rule.active == false
    end

    test "returns error changeset with invalid data" do
      assert {:error, %Ecto.Changeset{}} = Rules.create_rule(%{})
    end

    test "returns error with missing required fields" do
      alert_description = AlertDescriptionsFixtures.alert_description_fixture()

      invalid_attrs = %{
        alert_description_id: alert_description.id
        # missing name and action
      }

      assert {:error, changeset} = Rules.create_rule(invalid_attrs)

      assert errors_on(changeset) == %{
               name: ["can't be blank"],
               action: ["can't be blank"],
               rule_blocks: ["can't be blank"]
             }
    end

    test "validates rule name length" do
      alert_description = AlertDescriptionsFixtures.alert_description_fixture()

      attrs = %{
        # exceeds 150 char limit
        name: String.duplicate("a", 151),
        action: :notify,
        alert_description_id: alert_description.id,
        rule_blocks: [
          %{
            clauses: [
              %{field: "alert_title", operator: "is", value: "Test"}
            ]
          }
        ]
      }

      assert {:error, changeset} = Rules.create_rule(attrs)
      assert errors_on(changeset) == %{name: ["should be at most 150 character(s)"]}
    end

    test "validates action enum" do
      alert_description = AlertDescriptionsFixtures.alert_description_fixture()

      attrs = %{
        name: "Test Rule",
        action: :invalid_action,
        alert_description_id: alert_description.id,
        rule_blocks: [
          %{
            clauses: [
              %{field: "alert_title", operator: "is", value: "Test"}
            ]
          }
        ]
      }

      assert {:error, changeset} = Rules.create_rule(attrs)
      assert errors_on(changeset) == %{action: ["is invalid"]}
    end
  end

  describe "update_rule/2" do
    test "updates rule with valid data" do
      rule = rule_fixture()

      update_attrs = %{
        name: "Updated Rule Name",
        action: :nothing
      }

      assert {:ok, %Rule{} = updated_rule} = Rules.update_rule(rule, update_attrs)
      assert updated_rule.name == "Updated Rule Name"
      assert updated_rule.action == :nothing
    end

    test "strips active field from attrs" do
      rule = rule_fixture(%{active: false})

      update_attrs = %{
        name: "Updated Rule",
        # this should be ignored
        active: true
      }

      assert {:ok, %Rule{} = updated_rule} = Rules.update_rule(rule, update_attrs)
      # should remain false
      assert updated_rule.active == false
    end

    test "returns error changeset with invalid data" do
      rule = rule_fixture()

      assert {:error, %Ecto.Changeset{}} = Rules.update_rule(rule, %{name: nil})
    end
  end

  describe "delete_rule/1" do
    test "deletes the rule" do
      rule = rule_fixture()

      assert {:ok, %Rule{}} = Rules.delete_rule(rule)
      assert Rules.get_rule(rule.id) == nil
    end
  end

  describe "enable_rule/1" do
    test "activates an inactive rule and deactivates others" do
      alert_description = AlertDescriptionsFixtures.alert_description_fixture()

      active_rule = rule_fixture(%{alert_description_id: alert_description.id, active: true})
      inactive_rule = rule_fixture(%{alert_description_id: alert_description.id, active: false})

      assert {:ok, %{activate_current: activated_rule}} = Rules.enable_rule(inactive_rule)

      # reload from database
      reloaded_active = Rules.get_rule!(active_rule.id)
      reloaded_activated = Rules.get_rule!(activated_rule.id)

      # previously active rule should be deactivated
      assert reloaded_active.active == false
      # newly activated rule should be active
      assert reloaded_activated.active == true
    end

    test "returns rule unchanged when already active" do
      rule = rule_fixture(%{active: true})

      assert Rules.enable_rule(rule) == rule
    end

    test "works when no other rules are active" do
      rule = rule_fixture(%{active: false})

      assert {:ok, %{activate_current: activated_rule}} = Rules.enable_rule(rule)
      assert activated_rule.active == true
    end
  end

  describe "disable_rule/1" do
    test "deactivates an active rule" do
      rule = rule_fixture(%{active: true})

      assert {:ok, %Rule{} = deactivated_rule} = Rules.disable_rule(rule)
      assert deactivated_rule.active == false
    end

    test "returns rule unchanged when already inactive" do
      rule = rule_fixture(%{active: false})

      assert Rules.disable_rule(rule) == rule
    end
  end

  describe "increment_rule_hit_count/1" do
    test "increments the count by 1" do
      rule = rule_fixture(%{count: 5})

      assert {:ok, %Rule{} = updated_rule} = Rules.increment_rule_hit_count(rule)
      assert updated_rule.count == 6
    end

    test "increments from 0" do
      rule = rule_fixture(%{count: 0})

      assert {:ok, %Rule{} = updated_rule} = Rules.increment_rule_hit_count(rule)
      assert updated_rule.count == 1
    end
  end

  # Helper function to create test rules
  defp rule_fixture(attrs \\ %{}) do
    alert_description = AlertDescriptionsFixtures.alert_description_fixture()

    default_attrs = %{
      name: "Test Rule",
      action: :notify,
      action_value: "email",
      alert_description_id: alert_description.id,
      active: false,
      count: 0,
      rule_blocks: [
        %{
          clauses: [
            %{field: "alert_title", operator: "is", value: "Test Alert"}
          ]
        }
      ]
    }

    attrs = Map.merge(default_attrs, attrs)

    {:ok, rule} = Rules.create_rule(attrs)

    # If active was set in attrs, we need to enable it properly
    if Map.get(attrs, :active, false) do
      case Rules.enable_rule(rule) do
        # already active case
        %Rule{} = rule ->
          rule

        # activation successful
        {:ok, %{activate_current: rule}} ->
          rule
      end
    else
      rule
    end
  end
end
