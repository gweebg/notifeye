defmodule Notifeye.Monitoring.Alert do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @fields ~w(logz_id alert_title alert_description alert_severity alert_event_samples alert_tags start end)a
  @required_fields ~w(logz_id alert_title alert_severity alert_event_samples alert_tags)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "alerts" do
    field :logz_id, :string
    field :alert_title, :string
    field :alert_description, :string
    field :alert_severity, :string
    field :alert_event_samples, :string
    field :alert_tags, {:array, :string}
    field :start, :utc_datetime
    field :end, :utc_datetime
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(alert, attrs, user_scope) do
    alert
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> put_change(:user_id, user_scope.user.id)
  end
end
