defmodule Notifeye.AlertDescriptions.AlertDescription.Rule do
  @moduledoc """
  A rule that defines notification behavior for alerts matching certain criteria.
  Contains rule blocks (OR'ed together) with rule clauses (AND'ed within blocks).
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Notifeye.Notifications.Dispatcher
  alias Notifeye.AlertDescriptions.AlertDescription
  alias Notifeye.AlertDescriptions.AlertDescription.RuleBlock

  @optional_fields ~w(action_value)a
  @required_fields ~w(name action alert_description_id)a

  @actions ~w(notify nothing)a
  @notification_methods Dispatcher.available_providers()

  schema "alert_description_rules" do
    field :name, :string
    field :active, :boolean, default: true
    field :count, :integer, default: 0
    field :action, Ecto.Enum, values: @actions
    field :action_value, :string

    belongs_to :alert_description, AlertDescription
    embeds_many :rule_blocks, RuleBlock

    timestamps(type: :utc_datetime)
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, max: 150)
    |> validate_action()
    |> cast_embed(:rule_blocks, required: true)
    |> validate_rule_blocks()
  end

  defp validate_action(changeset) do
    case get_field(changeset, :action) do
      "notify" ->
        changeset
        |> validate_required([:action_value])
        |> validate_notification_methods()

      _ ->
        changeset
    end
  end

  defp validate_notification_methods(changeset) do
    case get_field(changeset, :action_value) do
      # this will be caught by validate_required anyway
      nil ->
        changeset

      action_value ->
        methods =
          action_value
          |> String.split(",")
          |> Enum.map(&String.trim/1)

        invalid_methods = methods -- @notification_methods

        if invalid_methods == [] do
          changeset
        else
          add_error(
            changeset,
            :action_value,
            "contains invalid notification methods: #{Enum.join(invalid_methods, ", ")}"
          )
        end
    end
  end

  defp validate_rule_blocks(changeset) do
    rule_blocks = get_field(changeset, :rule_blocks) || []

    case rule_blocks do
      [] -> add_error(changeset, :rule_blocks, "must have at least one rule block")
      _ -> changeset
    end
  end

  def valid_actions, do: @actions
end
