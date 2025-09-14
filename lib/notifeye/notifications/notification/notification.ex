defmodule Notifeye.Notifications.Notification do
  @moduledoc """
  Records of sent notifications for auditing and dashboard purposes.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Notifeye.{Accounts, Utils}
  alias Notifeye.Notifications.Message

  @types ~w(description_created assignment_created lead_notification group_notification)a

  @optional_fields ~w(results metadata providers success data)a
  @required_fields ~w(type oban_job_id recipient_id)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notifications" do
    field :type, Ecto.Enum, values: @types
    field :success, :boolean

    field :providers, {:array, :string}

    field :data, :map
    field :metadata, :map
    field :results, :map

    field :oban_job_id, :integer
    belongs_to :recipient, Accounts.User, foreign_key: :recipient_id, type: :integer

    timestamps()
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  @doc """
  Convert a `%Message{}` struct into a `%Notification{}` so it can be persisted to the
  database.

  Raises if `oban_job_id` is `nil`.
  """
  def from_message({status, %Message{} = message}, oban_job_id) when oban_job_id != nil do
    providers = message.providers |> Enum.map(& &1.provider_name())
    success = if status == :ok, do: true, else: false

    %__MODULE__{
      type: message.type,
      success: success,
      providers: providers,
      metadata: message.metadata,
      results: Utils.encode(message.results),
      recipient_id: message.to.id,
      oban_job_id: oban_job_id
    }
  end

  @doc """
  Returns a map containing which providers of a notification succeeded or failed.

  ## Examples

      iex> split_results(%Notification{} = n)
      %{
        ok: [...],
        error: [...]
      }
  """
  def split_results(%__MODULE__{} = notification) do
    {success, fail} =
      notification.results
      |> Enum.split_with(fn {_provider, result} -> match?({:ok, _}, result) end)

    %{
      ok: Enum.map(success, &elem(&1, 0)),
      error: Enum.map(fail, &elem(&1, 0))
    }
  end

  def types(), do: @types
end
