defmodule Notifeye.Alerts.Alert do
  use Ecto.Schema
  import Ecto.Changeset

  @fields ~w(alert_id title description definition_id severity tags samples)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "alerts" do
    field :alert_id, :string
    field :definition_id, :string
    field :title, :string
    field :description, :string
    field :severity, :string
    field :tags, :string
    field :samples, :string

    timestamps(type: :utc_datetime)
  end

  # todo: maybe use enum for severity
  # todo: maybe use jsonb for samples
  # todo: maybe use list for tags

  @doc false
  def changeset(alert, attrs) do
    alert
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
