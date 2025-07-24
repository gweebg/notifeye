defmodule Notifeye.AlertAssignments.AlertAssignment.Metadata do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @change_values ~w(increase decrease)a

  @fields ~w(change_action change_amount recurrent closed_at)a
  @required_fields ~w()a

  embedded_schema do
    field :change_action, Ecto.Enum, values: @change_values
    field :change_amount, :integer
    field :recurrent, :boolean, default: false
    field :closed_at, :utc_datetime
  end

  @doc false
  def changeset(metadata, attrs) do
    metadata
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  @doc """
  Changeset for acknowledging an assignmen.
  """
  def acknowledge_changeset(metadata, attrs) do
    metadata
    |> cast(attrs, @fields)
    |> validate_required([:change_action, :change_amount, :closed_at])
    |> validate_inclusion(:change_action, @change_values)
  end
end
