defmodule NotifeyeWeb.AdminLive.AlertDescriptions.Index do
  @moduledoc false

  use NotifeyeWeb, :live_view

  alias Notifeye.AlertDescriptions
  alias Notifeye.Notifications

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      AlertDescriptions.subscribe("new_description")
      AlertDescriptions.subscribe("deleted_description")
    end

    notification_groups = Notifications.list_notification_groups()

    socket =
      socket
      |> assign(:notification_groups, notification_groups)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:ok, {alert_descriptions, meta}} =
      AlertDescriptions.list_alert_descriptions_paginated(params, 10, [:user, :notification_group])

    {:noreply,
     socket
     |> assign(:meta, meta)
     |> stream(:alert_descriptions, alert_descriptions, reset: true)}
  end

  @impl true
  def handle_info({:new_description, alert_description}, socket) do
    alert_description = Notifeye.Repo.preload(alert_description, [:user, :notification_group])

    {:noreply,
     socket
     |> stream_insert(:alert_descriptions, alert_description, at: 0)}
  end

  @impl true
  def handle_info({:deleted_description, alert_description}, socket) do
    {:noreply,
     socket
     |> stream_delete(:alert_descriptions, alert_description)}
  end

  @impl true
  def handle_event("update-filter", %{"filters" => filters}, socket) do
    params =
      filters
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {{k, v}, i}, acc ->
        op = if k == "pattern", do: "ilike", else: "=="
        v = if op == "ilike", do: "#{v}", else: v

        Map.merge(acc, %{
          "filters[#{i}][field]" => k,
          "filters[#{i}][op]" => op,
          "filters[#{i}][value]" => v
        })
      end)

    {:noreply,
     socket
     |> push_patch(to: ~p"/admin/alert-descriptions?#{params}")}
  end

  @impl true
  def handle_event("update-filter", _params, socket) do
    {:noreply, socket}
  end
end
