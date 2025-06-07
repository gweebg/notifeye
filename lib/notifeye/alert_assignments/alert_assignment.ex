defmodule Notifeye.AlertAssignments.AlertAssignment do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @status ~w(unassigned open waiting closed)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "alert_assignments" do
    field :match, :string
    field :status, Ecto.Enum, values: @status, default: :unassigned

    belongs_to :user, Notifeye.Accounts.User
    belongs_to :alert_description, Notifeye.AlertDescriptions.AlertDescription

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(alert_assignment, attrs) do
    alert_assignment
    |> cast(attrs, [:match, :status])
    |> validate_required([:match, :status])
  end
end
