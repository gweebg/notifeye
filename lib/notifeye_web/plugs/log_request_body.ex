defmodule NotifeyeWeb.Plugs.LogRequestBody do
  @moduledoc """
  Log the request body into a file for data analysis purpouses.
  """

  @log_location "docs/collect/bodies.txt"

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    {:ok, body, _} = read_body(conn)

    {:ok, file} = File.open(@log_location, [:append])
    IO.write(file, body <> "\n")
    File.close(file)

    conn
  end
end
