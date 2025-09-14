defmodule Notifeye.Utils do
  def encode(map) when is_map(map) do
    map
    |> Enum.into(%{}, fn {k, v} -> {k, encode(v)} end)
  end

  def encode({status, value}) do
    %{"status" => status, "value" => encode(value)}
  end

  def encode(list) when is_list(list) do
    Enum.map(list, &encode/1)
  end

  def encode(value), do: value
end
