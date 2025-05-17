defmodule Notifeye.EctoTypes.UnixTimestamp do
  @moduledoc """
  Creates a custom type for unix timestamp
  """

  @behaviour Ecto.Type

  alias Ecto.Type

  def type, do: :utc_datetime

  def cast(timestamp) when is_integer(timestamp), do: DateTime.from_unix(timestamp)

  def cast(timestamp) when is_binary(timestamp) do
    with {int, _} <- Integer.parse(timestamp),
         {:ok, datetime} = DateTime.from_unix(int, :millisecond) do
      {:ok, DateTime.truncate(datetime, :second)}
    else
      error -> error
    end
  end

  def cast(_), do: :error

  def dump(value), do: Type.dump(:utc_datetime, value)

  def load(value), do: Type.load(:utc_datetime, value)

  def embed_as(_format), do: :self

  def equal?(term1, term2) do
    term1 == term2
  end
end
