defmodule Logzio.Logzio do
  @adapter Application.compile_env(:logzio, :adapter, Logzio.LogzioClient)

  @type return :: {:ok, any()} | {:error, any()}

  @callback me() :: return()
  defdelegate me, to: @adapter
end
