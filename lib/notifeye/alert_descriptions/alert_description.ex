defmodule Notifeye.AlertDescriptions.AlertDescription do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(id state verified)a
  @fields @required_fields ++ ~w(pattern edited_by notification_group_id)a
  @states ~w(disabled enabled grouponly)a

  @primary_key {:id, :integer, autogenerate: false}
  @foreign_key_type :binary_id
  schema "alert_descriptions" do
    field :state, Ecto.Enum, values: @states, default: :disabled
    field :pattern, :string
    field :verified, :boolean, default: false

    belongs_to :user, Notifeye.Accounts.User, foreign_key: :edited_by
    belongs_to :notification_group, Notifeye.Notifications.NotificationGroup

    has_many :alert_assignments, Notifeye.AlertAssignments.AlertAssignment, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc """
  Alert descriptions are automatically created by the system when a new unknown alert is received,
  thus, its `id` is the same as the `logz_id` of the alert and must be set manually.
  """
  def changeset(alert_description, attrs) do
    alert_description
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  # defp validate_pattern(changeset) do
  #   case get_field(changeset, :pattern) do
  #     nil ->
  #       changeset

  #     pattern ->
  #       with {:ok, regex} <- Regex.compile(pattern),
  #            %{"user" => _} <- Regex.named_captures(regex, "") do
  #         changeset
  #       else
  #         {:error, {reason, pos}} ->
  #           add_error(changeset, :pattern, "invalid regex: #{inspect(reason)} at position #{pos}")

  #         nil ->
  #           add_error(changeset, :pattern, "named capture 'user' is mandatory in the pattern")
  #       end
  #   end
  # end
end
