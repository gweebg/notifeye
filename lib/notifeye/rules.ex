defmodule Notifeye.Rules do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Notifeye.Repo
  alias Ecto.Multi

  alias Notifeye.AlertDescriptions.AlertDescription.Rule

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
    |> order_by([r], asc: :active)
    |> Repo.all()
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
end
