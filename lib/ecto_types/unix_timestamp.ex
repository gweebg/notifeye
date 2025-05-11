defmodule Notifeye.EctoTypes.UnixTimestamp do
  @moduledoc """
  Creates a custom type for unix timestamp
  """

  @behaviour Ecto.Type

  alias Ecto.Type

  def type, do: :utc_datetime

  def cast(timestamp) when is_integer(timestamp), do: DateTime.from_unix(timestamp)
  def cast(_), do: :error

  def dump(value), do: Type.dump(:utc_datetime, value)

  def load(value), do: Type.load(:utc_datetime, value)

  def embed_as(_format), do: :self

  def equal?(term1, term2) do
    term1 == term2
  end
end
