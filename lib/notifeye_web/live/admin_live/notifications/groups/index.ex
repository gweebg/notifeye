defmodule NotifeyeWeb.AdminLive.Notifications.Groups.Index do
  @moduledoc false

  use NotifeyeWeb, :live_view
  use NotifeyeWeb.Components

  alias Notifeye.Notifications
  alias Notifeye.Accounts

  @impl true
  def mount(_params, _session, socket) do
    # todo: subscribe to topics

    {:ok,
     socket
     |> assign(:show_help, false)
     |> assign(:all_users, Accounts.list_users_to_filter())
     |> assign(:selected_users, [])
     |> assign(:user_search, "")
     |> assign(:filtered_users, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page_size = Map.get(params, "page_size", "10")
    adding = Map.get(params, "adding") == "true"

    # filters = filters_from_params(params)

    {:ok, {groups, meta}} =
      Notifications.list_notification_groups_flop(params, page_size: page_size)

    socket =
      socket
      |> assign(:meta, meta)
      |> assign(:page_size, page_size)
      |> assign(:current_params, params)
      |> assign(:adding, adding)
      |> stream(:groups, groups, reset: true)

    socket =
      if adding do
        socket
        |> assign(
          :form,
          to_form(Notifications.change_notification_group(%Notifications.NotificationGroup{}))
        )
        |> assign(
          :filtered_users,
          Accounts.filter_users(socket.assigns.all_users, socket.assigns.user_search)
        )
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("open_help", _params, socket) do
    {:noreply, assign(socket, :show_help, true)}
  end

  @impl true
  def handle_event("close_help", _params, socket) do
    {:noreply, assign(socket, :show_help, false)}
  end

  @impl true
  def handle_event("open_add_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/descriptions/groups?adding=true")}
  end

  @impl true
  def handle_event("close_add_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_users, [])
     |> assign(:user_search, "")
     |> push_patch(to: ~p"/admin/descriptions/groups")}
  end

  @impl true
  def handle_event("validate", %{"notification_group" => params}, socket) do
    changeset =
      %Notifications.NotificationGroup{}
      |> Notifications.change_notification_group(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"notification_group" => params}, socket) do
    case Notifications.create_notification_group(params) do
      {:ok, notification_group} ->
        socket
        |> maybe_add_selected_users(notification_group)
        |> stream_insert(:groups, notification_group, at: 0)
        |> assign(
          selected_users: [],
          user_search: ""
        )
        |> put_flash(:info, "Notification group created successfully")
        |> push_patch(to: ~p"/admin/descriptions/groups")
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        noreply(assign(socket, form: to_form(changeset)))
    end
  end

  @impl true
  def handle_event("search_users", %{"value" => search_term}, socket) do
    filtered_users = Accounts.filter_users(socket.assigns.all_users, search_term)

    {:noreply,
     socket
     |> assign(:user_search, search_term)
     |> assign(:filtered_users, filtered_users)}
  end

  @impl true
  def handle_event("toggle_user", %{"user_id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    selected_users = socket.assigns.selected_users

    updated_users =
      if user_id in selected_users do
        List.delete(selected_users, user_id)
      else
        [user_id | selected_users]
      end

    {:noreply, assign(socket, selected_users: updated_users)}
  end

  defp noreply(socket), do: {:noreply, socket}

  defp maybe_add_selected_users(socket, notification_group) do
    case socket.assigns.selected_users do
      [] ->
        socket

      user_ids ->
        users = Notifeye.Accounts.User |> Notifeye.Repo.get!(user_ids)
        Notifications.update_notification_group_users(notification_group, users)
        socket
    end
  end
end
