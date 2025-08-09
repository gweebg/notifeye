defmodule Notifeye.AlertDescriptions.AlertDescription.RuleClause do
  @moduledoc """
  An embedded schema that represents a rule in the description ruleset.
  Defines whether an alert is sent or not.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @optional_fields ~w()a
  @required_fields ~w(field operator value)a

  @severities ~w(low medium high)

  @field_definitions %{
    "alert_title" => %{operators: ~w(matches is is_not)},
    "alert_description" => %{operators: ~w(matches is is_not)},
    "alert_severity" => %{operators: ~w(is is_not), values: @severities},
    "alert_tags" => %{operators: ~w(include doesnt_include)},
    "start" => %{operators: ~w(after before equal), format: :time},
    "end" => %{operators: ~w(after before equal), format: :time},
    "inserted_at" => %{operators: ~w(after before equal), format: :datetime}
  }

  @valid_fields Map.keys(@field_definitions)

  embedded_schema do
    field :field, :string
    field :operator, :string
    field :value, :string
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:field, @valid_fields)
    |> validate_operator()
    |> validate_value()
  end

  defp validate_operator(changeset) do
    field = get_field(changeset, :field)
    valid_ops = @field_definitions[field][:operators] || []
    validate_inclusion(changeset, :operator, valid_ops)
  end

  defp validate_value(changeset) do
    field = get_field(changeset, :field)
    validate_field_value_match(changeset, field)
  end

  defp validate_field_value_match(changeset, field) do
    case @field_definitions[field] do
      %{format: :time} ->
        validate_iso_format(
          changeset,
          :value,
          &Time.from_iso8601/1,
          "must be a valid time format (HH:MM:SS)"
        )

      %{format: :datetime} ->
        validate_iso_format(
          changeset,
          :value,
          &DateTime.from_iso8601/1,
          "must be a valid datetime format"
        )

      %{values: allowed} ->
        validate_inclusion(changeset, :value, allowed)

      _ ->
        changeset
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

  def valid_fields, do: @valid_fields
  def valid_operators_for_field(field), do: @field_definitions[field][:operators] || []
  def valid_severities, do: @severities
end
