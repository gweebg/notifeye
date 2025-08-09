defmodule Notifeye.AlertDescriptions.AlertDescription.RuleBlock do
  @moduledoc """
  A rule block containing one or more rules connected by AND logic.
  Multiple blocks are OR'ed together to form the complete ruleset.
  One clause can be marked as default (fallback and default on description
  creation).
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Notifeye.AlertDescriptions.AlertDescription.RuleClause

  embedded_schema do
    embeds_many :clauses, RuleClause
  end

  def changeset(rule_block, attrs) do
    rule_block
    |> cast(attrs, [])
    |> cast_embed(:clauses, required: true)
    |> validate_rules()
  end

  def building_changeset(rule_block, attrs) do
    rule_block
    |> cast(attrs, [])
    |> cast_embed(:clauses, with: &RuleClause.building_changeset/2)
  end

  defp validate_rules(changeset) do
    rules = get_field(changeset, :clauses) || []

    case rules do
      [] -> add_error(changeset, :clauses, "a rule block must contain at least one rule clause")
      _ -> changeset
    end
  end
end
