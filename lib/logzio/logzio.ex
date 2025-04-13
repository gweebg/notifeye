defmodule Logzio.Logzio do
  @moduledoc false

  @adapter Application.compile_env(:logzio, :adapter, Logzio.LogzioClient)

  @type return :: {:ok, any()} | {:error, any()}

  @callback me() :: return()
  defdelegate me, to: @adapter

  @callback get_alert_by_id(pos_integer()) :: return()
  defdelegate get_alert_by_id(alert_id), to: @adapter
end
