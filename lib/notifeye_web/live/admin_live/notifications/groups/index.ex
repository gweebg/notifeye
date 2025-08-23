defmodule NotifeyeWeb.AdminLive.Notifications.Groups.Index do
  @moduledoc false

  use NotifeyeWeb, :live_view
  use NotifeyeWeb.Components

  alias Notifeye.Notifications
  alias Notifeye.Accounts
  alias NotifeyeWeb.Components.Modals.NotificationGroupShow

  @impl true
  def mount(_params, _session, socket) do
    # todo: subscribe to topics

    {:ok,
     socket
     |> assign(:show_help, false)
     |> assign(:all_users, Accounts.list_users_to_filter())
     |> assign(:selected_users, [])
     |> assign(:user_search, "")
     |> assign(:filtered_users, [])
     |> assign(:editing_group, nil)
     |> assign(:show_delete_confirmation, false)
     |> assign(:showing_group, nil)
     |> assign(:group_alert_descriptions, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page_size = Map.get(params, "page_size", "10")
    adding = Map.get(params, "adding") == "true"
    editing_id = Map.get(params, "editing")

    # filters = filters_from_params(params)

    # todo: handle page_size with pagination
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
      cond do
        adding ->
          socket
          |> assign(:editing_group, nil)
          |> assign(
            :form,
            to_form(Notifications.change_notification_group(%Notifications.NotificationGroup{}))
          )
          |> assign(:selected_users, [])
          |> assign(
            :filtered_users,
            Accounts.filter_users(socket.assigns.all_users, socket.assigns.user_search)
          )

        editing_id ->
          editing_group = Notifications.get_notification_group_with_users!(editing_id)
          selected_user_ids = Enum.map(editing_group.users, & &1.id)

          socket
          |> assign(:editing_group, editing_group)
          |> assign(
            :form,
            to_form(Notifications.change_notification_group(editing_group))
          )
          |> assign(:selected_users, selected_user_ids)
          |> assign(
            :filtered_users,
            Accounts.filter_users(socket.assigns.all_users, socket.assigns.user_search)
          )

        true ->
          socket
          |> assign(:editing_group, nil)
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
    {:noreply, push_patch(socket, to: ~p"/notifications/groups?adding=true")}
  end

  @impl true
  def handle_event("close_add_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_users, [])
     |> assign(:user_search, "")
     |> assign(:editing_group, nil)
     |> assign(:show_delete_confirmation, false)
     |> push_patch(to: ~p"/notifications/groups")}
  end

  @impl true
  def handle_event("edit_group", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/notifications/groups?editing=#{id}")}
  end

  @impl true
  def handle_event("show_group", %{"id" => id}, socket) do
    group = Notifications.get_notification_group_with_users!(id)

    alert_descriptions =
      Notifeye.AlertDescriptions.list_alert_descriptions_for_notification_group(id)

    {:noreply,
     socket
     |> assign(:showing_group, group)
     |> assign(:group_alert_descriptions, alert_descriptions)}
  end

  @impl true
  def handle_event("close_show_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:showing_group, nil)
     |> assign(:group_alert_descriptions, [])}
  end

  @impl true
  def handle_event("validate", %{"notification_group" => params}, socket) do
    changeset =
      (socket.assigns.editing_group || %Notifications.NotificationGroup{})
      |> Notifications.change_notification_group(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"notification_group" => params}, socket) do
    if socket.assigns.editing_group do
      update_group(socket, params)
    else
      create_group(socket, params)
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

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    {:noreply, assign(socket, show_delete_confirmation: true)}
  end

  @impl true
  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, show_delete_confirmation: false)}
  end

  @impl true
  def handle_event("delete_group", _params, socket) do
    case Notifications.delete_notification_group(socket.assigns.editing_group) do
      {:ok, _notification_group} ->
        {:noreply,
         socket
         |> stream_delete(:groups, socket.assigns.editing_group)
         |> assign(:show_delete_confirmation, false)
         |> assign(:editing_group, nil)
         |> put_flash(:info, "Notification group deleted successfully")
         |> push_patch(to: ~p"/notifications/groups")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(:show_delete_confirmation, false)
         |> put_flash(:error, "Could not delete notification group")}
    end
  end

  defp create_group(socket, params) do
    case Notifications.create_notification_group(params) do
      {:ok, notification_group} ->
        socket
        |> maybe_add_selected_users(notification_group)
        |> stream_insert(:groups, notification_group, at: 0)
        |> assign(
          selected_users: [],
          user_search: "",
          editing_group: nil
        )
        |> put_flash(:info, "Notification group created successfully")
        |> push_patch(to: ~p"/notifications/groups")
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        noreply(assign(socket, form: to_form(changeset)))
    end
  end

  defp update_group(socket, params) do
    case Notifications.update_notification_group(socket.assigns.editing_group, params) do
      {:ok, notification_group} ->
        socket
        |> maybe_update_selected_users(notification_group)
        |> stream_insert(:groups, notification_group)
        |> assign(
          selected_users: [],
          user_search: "",
          editing_group: nil
        )
        |> put_flash(:info, "Notification group updated successfully")
        |> push_patch(to: ~p"/notifications/groups")
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        noreply(assign(socket, form: to_form(changeset)))
    end
  end

  defp noreply(socket), do: {:noreply, socket}

  defp maybe_add_selected_users(socket, notification_group) do
    case socket.assigns.selected_users do
      [] ->
        socket

      user_ids ->
        users = Enum.map(user_ids, &Accounts.get_user!/1)
        Notifications.update_notification_group_users(notification_group, users)
        socket
    end
  end

  defp maybe_update_selected_users(socket, notification_group) do
    case socket.assigns.selected_users do
      [] ->
        # clear all users from the group
        Notifications.update_notification_group_users(notification_group, [])
        socket

      user_ids ->
        users = Enum.map(user_ids, &Accounts.get_user!/1)
        Notifications.update_notification_group_users(notification_group, users)
        socket
    end
  end
end
