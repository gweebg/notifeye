defmodule Notifeye.Rules do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Notifeye.Repo
  alias Ecto.Multi

  alias Notifeye.AlertDescriptions.AlertDescription.{Rule, RuleBlock, RuleClause}
  alias Notifeye.AlertDescriptions.Rule.Fields

  def get_rule(id), do: Repo.get(Rule, id)
  def get_rule!(id), do: Repo.get!(Rule, id)

  def get_active_rule(alert_description_id) do
    Rule
    |> where([r], r.alert_description_id == ^alert_description_id)
    |> where([r], r.active == true)
    |> limit(1)
    |> Repo.one()
  end

  def list_rules(alert_description_id) do
    Rule
    |> where([r], r.alert_description_id == ^alert_description_id)
    |> Repo.all()
  end

  def list_rules_flop(flop, alert_description_id) when is_integer(alert_description_id) do
    query =
      Rule
      |> where([r], r.alert_description_id == ^alert_description_id)

    Flop.validate_and_run(query, flop, for: Rule)
  end

  def create_rule(attrs \\ %{}) do
    # drop :active field, as we only allow its setting via dedicated function
    attrs = Map.delete(attrs, :active)

    %Rule{}
    |> Rule.changeset(attrs)
    |> Repo.insert()
  end

  def update_rule(%Rule{} = rule, attrs) do
    # drop :active field, as we only allow its setting via dedicated function
    attrs = Map.delete(attrs, :active)

    rule
    |> Rule.changeset(attrs)
    |> Repo.update()
  end

  def delete_rule(%Rule{} = rule) do
    Repo.delete(rule)
  end

  def change_rule(%Rule{} = rule, attrs \\ %{}) do
    Rule.changeset(rule, attrs)
  end

  def enable_rule(%Rule{active: true} = rule), do: rule

  def enable_rule(%Rule{active: false} = rule) do
    Multi.new()
    |> Multi.update_all(
      :deactivate_others,
      Rule
      |> where([r], r.alert_description_id == ^rule.alert_description_id)
      |> where([r], r.active == true),
      set: [active: false]
    )
    |> Multi.update(:activate_current, change_rule(rule, %{active: true}))
    |> Repo.transaction()
  end

  def disable_rule(%Rule{active: false} = rule), do: rule

  def disable_rule(%Rule{active: true} = rule) do
    rule
    |> change_rule(%{active: false})
    |> Repo.update()
  end

  def increment_rule_hit_count(%Rule{} = rule) do
    update_rule(rule, %{count: rule.count + 1})
  end

  def new_rule_changeset(alert_description_id) do
    %Rule{alert_description_id: alert_description_id}
    |> Rule.new_with_defaults()
  end

  def change_rule_building(%Rule{} = rule, attrs \\ %{}) do
    Rule.building_changeset(rule, attrs)
  end

  @doc """
  Apply the active rule of an `%AlertDescription{}` to an `%Alert{}`.

  Upon receiving an alert, if the corresponding description exists and there's
  a rule enabled, we apply the rule, checking whether the notification should
  be sent via the methods specified on the active rule.

  The `%Rule{}` structure itself already specifies the logic connectors between
  clauses. Each `%RuleBlock{}` is OR'ed together, and each `%RuleClause{}` of a
  `%RuleBlock{}` is AND'ed together. This results in a boolean value indicating
  whether the rule matched the alert or not.

  Returns `true` if the alert satisfies the conditions of the rule, `false`
  otherwise.

  todo: enable rules on processor
  """
  def check(alert_description_id, alert) do
    alert_description_id
    |> get_active_rule()
    |> apply_rule(alert)
  end

  defp apply_rule(nil, _alert), do: false

  defp apply_rule(%Rule{} = rule, alert) do
    # any?/2 OR's stuff
    Enum.any?(rule.rule_blocks, &apply_block(&1, alert))
  end

  defp apply_block(%RuleBlock{clauses: clauses}, alert) do
    # all?/2 AND's stuff
    Enum.all?(clauses, &apply_clause(&1, alert))
  end

  defp apply_clause(%RuleClause{field: field, operator: op, value: value}, alert) do
    alert_value = Fields.alert_field_mapping(alert, field)
    evaluate_condition(alert_value, op, value)
  end

  defp evaluate_condition(field, operator, expected_value) do
    case Fields.op_to_func(operator) do
      nil -> false
      fun -> fun.(field, expected_value)
    end
  end

  def stringify(%Rule{} = rule) do
    rule.rule_blocks
    |> Enum.map_join(" OR ", &block_to_expression/1)
  end

  defp block_to_expression(%RuleBlock{clauses: clauses}) do
    clauses
    |> Enum.map_join(" AND ", &clause_to_expression/1)
    |> wrap_if_needed(length(clauses) > 1)
  end

  defp clause_to_expression(%RuleClause{field: field, operator: op, value: value}) do
    formatted_value =
      case Fields.format_for(field) do
        :datetime -> "\"#{value}\""
        :time -> "\"#{value}\""
        _ -> inspect(value)
      end

    "#{field} #{op} #{formatted_value}"
  end

  defp wrap_if_needed(str, true), do: "(" <> str <> ")"
  defp wrap_if_needed(str, false), do: str
end
