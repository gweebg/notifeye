defmodule Notifeye.AlertAssignments.AlertAssignment do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Notifeye.AlertAssignments.AlertAssignment

  @status ~w(unassigned open closed expired)a

  @fields ~w(match status user_id alert_description_id alert_id)a
  @required_fields ~w(match user_id alert_description_id)a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "alert_assignments" do
    field :match, :string
    field :status, Ecto.Enum, values: @status, default: :open

    embeds_one :metadata, AlertAssignment.Metadata, on_replace: :update

    belongs_to :user, Notifeye.Accounts.User
    belongs_to :alert, Notifeye.Monitoring.Alert, type: :binary_id
    belongs_to :alert_description, Notifeye.AlertDescriptions.AlertDescription

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for updating any field of the assignment. Guarantees the present
  of the `metadata` field.
  """
  def changeset(alert_assignment, attrs) do
    alert_assignment
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> ensure_metadata()
    |> cast_embed(:metadata)
  end

  defp ensure_metadata(%Ecto.Changeset{data: %{metadata: nil}, changes: changes} = changeset) do
    if Map.has_key?(changes, :metadata) do
      changeset
    else
      changeset
      |> put_embed(:metadata, %{})
    end
  end

  defp ensure_metadata(%Ecto.Changeset{} = changeset), do: changeset

  @doc """
  Changeset for only updating the metadata of an assignment. Ignores 
  assignment fields.
  """
  def metadata_changeset(alert_assignment, attrs) do
    alert_assignment
    |> cast(attrs, [])
    |> cast_embed(:metadata, with: &AlertAssignment.Metadata.changeset/2)
  end

  @doc """
  Changeset for acknowledging an assignment. Ensures that the fields
  `change_action` and `change_amount` are specified, sets the assignment to
  `closed` and fills the `closed_at` field with the current time.
  """
  def acknowledge_changeset(%AlertAssignment{} = alert_assignment, attrs) do
    attrs =
      Map.put_new_lazy(attrs, :closed_at, fn -> DateTime.utc_now() end)

    alert_assignment
    |> cast(%{status: :closed}, [:status])
    |> put_embed(:metadata, build_metadata(alert_assignment.metadata, attrs))
  end

  defp build_metadata(metadata, attrs),
    do: AlertAssignment.Metadata.acknowledge_changeset(metadata, attrs)
end
