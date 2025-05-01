defmodule NotifeyeWeb.PageController do
  use NotifeyeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
