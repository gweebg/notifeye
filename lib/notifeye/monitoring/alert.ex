defmodule Notifeye.Monitoring.Alert do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Notifeye.EctoTypes.UnixTimestamp

  @fields ~w(logz_id alert_title alert_description alert_severity alert_event_samples alert_tags start end)a
  @required_fields ~w(logz_id alert_title alert_severity alert_event_samples alert_tags)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, except: [:user, :alert_assignments, :id, :__meta__]}
  schema "alerts" do
    field :logz_id, :integer

    field :alert_title, :string
    field :alert_description, :string
    field :alert_severity, :string
    field :alert_event_samples, :string
    field :alert_tags, {:array, :string}

    field :start, UnixTimestamp
    field :end, UnixTimestamp

    belongs_to :user, Notifeye.Accounts.User, type: :id
    has_many :alert_assignments, Notifeye.AlertAssignments.AlertAssignment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(alert, attrs, user_scope) do
    alert
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> normalize_severity()
    |> put_change(:user_id, user_scope.user.id)
  end

  defp normalize_severity(changeset) do
    case get_change(changeset, :alert_severity) do
      nil -> changeset
      severity -> put_change(changeset, :alert_severity, String.downcase(severity))
    end
  end
end
