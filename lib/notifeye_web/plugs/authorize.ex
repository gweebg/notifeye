defmodule NotifeyeWeb.Plugs.Authorize do
  @moduledoc """
  A plug to authorize access based on user roles.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, role) do
    user = conn.assigns.current_scope.user

    case user.role do
      ^role ->
        conn

      _ ->
        conn
        |> put_flash(:error, "You are not authorized to access this page.")
        |> redirect(to: "/")
        |> halt()
    end
  end
end
