defmodule Notifeye.AlertDescriptions.AlertDescription.Rule do
  @moduledoc """
  A rule that defines notification behavior for alerts matching certain criteria.
  Contains rule blocks (OR'ed together) with rule clauses (AND'ed within blocks).
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Notifeye.Notifications.Providers
  alias Notifeye.AlertDescriptions.AlertDescription
  alias Notifeye.AlertDescriptions.AlertDescription.{RuleBlock, RuleClause}

  @optional_fields ~w(action_value active count)a
  @required_fields ~w(name action alert_description_id)a

  @actions ~w(notify nothing)a

  @derive {Flop.Schema,
           filterable: [:id, :name, :active],
           sortable: [:inserted_at, :id],
           default_order: %{order_by: [:inserted_at], order_directions: [:desc]}}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "alert_description_rules" do
    field :name, :string
    field :active, :boolean, default: false
    field :count, :integer, default: 0
    field :action, Ecto.Enum, values: @actions
    field :action_value, :string

    belongs_to :alert_description, AlertDescription, type: :integer
    embeds_many :rule_blocks, RuleBlock, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, max: 150)
    |> validate_action()
    |> cast_embed(:rule_blocks, required: true)
  end

  @doc """
  Changeset for building/editing rules without strict validation.
  Used during form interactions before final submission.
  """
  def building_changeset(rule, attrs) do
    rule
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_length(:name, max: 150)
    |> cast_embed(:rule_blocks, with: &RuleBlock.building_changeset/2)
  end

  @doc """
  Creates a new rule with default empty block and clause structure.
  """
  def new_with_defaults(rule) do
    default_block = %RuleBlock{clauses: [%RuleClause{}]}

    rule
    |> building_changeset(%{})
    |> put_embed(:rule_blocks, [default_block])
  end

  @doc """
  Adds an empty rule block to an existing rule changeset.
  Returns the updated changeset.
  """
  def add_block(%Ecto.Changeset{} = changeset) do
    rule_blocks = get_field(changeset, :rule_blocks) || []
    empty_block = %RuleBlock{clauses: [RuleClause.empty_clause()]}
    updated_blocks = rule_blocks ++ [empty_block]

    put_embed(changeset, :rule_blocks, updated_blocks)
  end

  @doc """
  Adds an empty rule clause to a specific rule block.
  Returns the updated changeset.
  """
  def add_clause(%Ecto.Changeset{} = changeset, block_index) do
    rule_blocks = get_field(changeset, :rule_blocks) || []

    case Enum.at(rule_blocks, block_index) do
      nil ->
        changeset

      block ->
        clauses = Map.get(block, :clauses, [])
        updated_clauses = clauses ++ [RuleClause.empty_clause()]
        updated_block = Map.put(block, :clauses, updated_clauses)
        updated_blocks = List.replace_at(rule_blocks, block_index, updated_block)

        put_embed(changeset, :rule_blocks, updated_blocks)
    end
  end

  @doc """
  Removes a rule block at the specified index.
  Returns the updated changeset.
  """
  def remove_block(%Ecto.Changeset{} = changeset, block_index) do
    rule_blocks = get_field(changeset, :rule_blocks) || []

    # Ensure we don't remove the last block
    if length(rule_blocks) > 1 do
      updated_blocks = List.delete_at(rule_blocks, block_index)
      put_embed(changeset, :rule_blocks, updated_blocks)
    else
      changeset
    end
  end

  @doc """
  Removes a rule clause at the specified block and clause indices.
  Returns the updated changeset.
  """
  def remove_clause(%Ecto.Changeset{} = changeset, block_index, clause_index) do
    rule_blocks = get_field(changeset, :rule_blocks) || []

    case Enum.at(rule_blocks, block_index) do
      nil ->
        changeset

      block ->
        clauses = Map.get(block, :clauses, [])

        # Ensure we don't remove the last clause from a block
        if length(clauses) > 1 do
          updated_clauses = List.delete_at(clauses, clause_index)
          updated_block = Map.put(block, :clauses, updated_clauses)
          updated_blocks = List.replace_at(rule_blocks, block_index, updated_block)

          put_embed(changeset, :rule_blocks, updated_blocks)
        else
          changeset
        end
    end
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

        available_methods = Providers.names()
        invalid_methods = methods -- available_methods

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

  def valid_actions, do: @actions
end
