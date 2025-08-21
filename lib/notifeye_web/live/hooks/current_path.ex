defmodule NotifeyeWeb.LiveHooks.CurrentPath do
  @moduledoc false

  use NotifeyeWeb, :live_view

  def on_mount(:current_path, _params, _session, socket) do
    {:cont,
     Phoenix.LiveView.attach_hook(socket, :current_path, :handle_params, &put_path_in_socket/3)}
  end

  defp put_path_in_socket(_params, url, socket) do
    {:cont, Phoenix.Component.assign(socket, :current_path, URI.parse(url).path)}
  end
end
