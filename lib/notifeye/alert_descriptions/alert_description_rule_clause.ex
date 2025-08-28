defmodule Notifeye.AlertDescriptions.AlertDescription.RuleClause do
  @moduledoc """
  An embedded schema that represents a rule in the description ruleset.
  Defines whether an alert is sent or not.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Notifeye.AlertDescriptions.Rule.Fields

  @optional_fields ~w()a
  @required_fields ~w(field operator value)a

  embedded_schema do
    field :field, :string
    field :operator, :string
    field :value, :string
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:field, Fields.valid_fields())
    |> validate_operator()
    |> validate_value()
  end

  def building_changeset(rule, attrs) do
    rule
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_inclusion(:field, Fields.valid_fields())
    |> validate_operator()
    |> validate_value()
  end

  defp validate_operator(changeset) do
    field = get_field(changeset, :field)
    validate_inclusion(changeset, :operator, Fields.valid_operators(field))
  end

  defp validate_value(changeset) do
    field = get_field(changeset, :field)
    validate_field_value_match(changeset, field)
  end

  defp validate_field_value_match(changeset, field) do
    case Fields.format_for(field) do
      :time ->
        validate_iso_format(
          changeset,
          :value,
          &Time.from_iso8601/1,
          "must be a valid time format (HH:MM:SS)"
        )

      :datetime ->
        validate_iso_format(
          changeset,
          :value,
          &DateTime.from_iso8601/1,
          "must be a valid datetime format"
        )

      _ ->
        allowed = Fields.valid_values(field)
        if allowed == [], do: changeset, else: validate_inclusion(changeset, :value, allowed)
    end
  end

  defp validate_iso_format(changeset, field, parser, error_msg) do
    case get_field(changeset, field) do
      nil ->
        changeset

      value ->
        case parser.(value) do
          {:ok, _} -> changeset
          {:ok, _, _} -> changeset
          _ -> add_error(changeset, field, error_msg)
        end
    end
  end

  def empty_clause() do
    %__MODULE__{
      field: "alert_title",
      operator: "is",
      value: ""
    }
  end
end
