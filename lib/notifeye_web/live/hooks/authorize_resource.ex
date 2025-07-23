defmodule NotifeyeWeb.LiveHooks.AuthorizeResource do
  @moduledoc false

  use NotifeyeWeb, :live_view

  import NotifeyeWeb.UserAuth, only: [mount_current_scope: 2]
  import Phoenix.LiveView

  def on_mount({:authorize_owner, fetcher_fun}, %{"id" => id}, session, socket) do
    socket = mount_current_scope(socket, session)
    scope_user_id = socket.assigns.current_scope.user.id

    case fetcher_fun.(id) do
      %{user_id: ^scope_user_id} = resource ->
        {:cont, assign(socket, :resource, resource)}

      nil ->
        {:cont, assign(socket, :resource, nil)}

      _ ->
        socket =
          socket
          |> put_flash(:error, "You are not authorized to access this page.")
          |> redirect(to: ~p"/")

        {:halt, socket}
    end
  end
end
