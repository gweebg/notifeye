defmodule NotifeyeWeb.LiveHooks.AuthorizeResource do
  @moduledoc false

  use NotifeyeWeb, :live_view

  import NotifeyeWeb.UserAuth, only: [mount_current_scope: 2]
  import Phoenix.LiveView

  def on_mount({:authorize_resource, fetcher_fun}, %{"id" => id}, session, socket) do
    socket = mount_current_scope(socket, session)
    current_scope = socket.assigns.current_scope

    case safe_fetch_resource(fetcher_fun, id) do
      {:ok, resource} -> handle_authorization(current_scope, resource, socket)
      {:error, _} -> handle_fetch_error(current_scope, socket)
    end
  end

  defp safe_fetch_resource(fetcher_fun, id) do
    try do
      {:ok, fetcher_fun.(id)}
    rescue
      _ -> {:error, :fetch_failed}
    end
  end

  defp handle_authorization(%{user: %{role: :admin}}, resource, socket) do
    {:cont, assign(socket, :resource, resource)}
  end

  defp handle_authorization(%{user: %{id: scope_user_id}}, resource, socket) do
    case resource do
      %{user_id: ^scope_user_id} -> {:cont, assign(socket, :resource, resource)}
      nil -> {:cont, assign(socket, :resource, nil)}
      _ -> {:halt, unauthorized_redirect(socket)}
    end
  end

  defp handle_authorization(_, _, socket) do
    {:halt, unauthenticated_redirect(socket)}
  end

  defp handle_fetch_error(%{user: %{role: :admin}}, socket) do
    {:cont, assign(socket, :resource, nil)}
  end

  defp handle_fetch_error(%{user: _}, socket) do
    {:halt, unauthorized_redirect(socket)}
  end

  defp handle_fetch_error(_, socket) do
    {:halt, unauthenticated_redirect(socket)}
  end

  defp unauthorized_redirect(socket) do
    socket
    |> put_flash(:error, "You are not authorized to access this page.")
    |> redirect(to: ~p"/")
  end

  defp unauthenticated_redirect(socket) do
    socket
    |> put_flash(:error, "You must log in to access this page.")
    |> redirect(to: ~p"/users/log-in")
  end
end
