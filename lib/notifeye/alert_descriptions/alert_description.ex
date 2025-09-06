defmodule Notifeye.AlertDescriptions.AlertDescription do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Notifeye.AlertDescriptions.AlertDescription

  @required_fields ~w(id name state verified)a
  @optional_fields ~w(pattern edited_by notification_group_id)a
  @states ~w(disabled enabled grouponly)a

  @derive {Flop.Schema,
           filterable: [
             :name,
             :state,
             :verified,
             :pattern,
             :notification_group_id,
             :edited_by,
             :id_search
           ],
           sortable: [:updated_at, :id, :state, :verified],
           default_order: %{order_by: [:updated_at], order_directions: [:desc]},
           adapter_opts: [
             custom_fields: [
               id_search: [
                 filter: {Notifeye.AlertDescriptions, :filter_by_id_like, []},
                 bindings: [:alert_description]
               ]
             ]
           ]}

  @primary_key {:id, :integer, autogenerate: false}
  @foreign_key_type :binary_id
  schema "alert_descriptions" do
    field :name, :string
    field :state, Ecto.Enum, values: @states, default: :disabled
    field :pattern, :string
    field :verified, :boolean, default: false

    belongs_to :user, Notifeye.Accounts.User, foreign_key: :edited_by, type: :integer
    belongs_to :notification_group, Notifeye.Notifications.NotificationGroup

    has_many :alert_assignments, Notifeye.AlertAssignments.AlertAssignment, on_replace: :delete
    has_many :rules, AlertDescription.Rule, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc """
  Alert descriptions are automatically created by the system when a new unknown alert is received,
  thus, its `id` is the same as the `logz_id` of the alert and must be set manually.
  """
  def changeset(alert_description, attrs) do
    alert_description
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
