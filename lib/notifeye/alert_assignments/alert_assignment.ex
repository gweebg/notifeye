defmodule Notifeye.AlertAssignments.AlertAssignment do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @fields ~w(match status user_id alert_description_id)a
  @required_fields ~w(match user_id alert_description_id)a

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
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
