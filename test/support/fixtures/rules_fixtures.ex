defmodule Notifeye.RulesFixtures do
  @moduledoc false

  alias Notifeye.Rules
  alias Notifeye.AlertDescriptionsFixtures
  alias Notifeye.AlertDescriptions.AlertDescription.Rule

  def rule_fixture(attrs \\ %{}) do
    default_attrs = %{
      name: "Rule #1",
      action: :notify,
      action_value: "email, rocket_chat",
      alert_description_id: AlertDescriptionsFixtures.alert_description_fixture().id,
      active: false,
      count: 0,
      rule_blocks: [
        single_clause_block("alert_title", "is", "Test Alert")
      ]
    }

    attrs = Map.merge(default_attrs, attrs)
    {:ok, rule} = Rules.create_rule(attrs)

    if Map.get(attrs, :active, false) do
      case Rules.enable_rule(rule) do
        %Rule{} = rule -> rule
        {:ok, %{activate_current: rule}} -> rule
      end
    else
      rule
    end
  end

  def single_clause_block(field, operator, value) do
    %{clauses: [%{field: field, operator: operator, value: value}]}
  end
end
