defmodule NotifeyeWeb.AdminLive.AlertDescriptions.Index do
  @moduledoc false

  use NotifeyeWeb, :live_view

  alias Notifeye.AlertDescriptions
  alias Notifeye.Notifications

  use NotifeyeWeb.Components

  @impl true
  def mount(_params, _session, socket) do
    topics = ~w(new_description updated_description deleted_description)

    if connected?(socket) do
      topics
      |> Enum.each(&AlertDescriptions.subscribe/1)
    end

    notification_groups = Notifications.list_notification_groups()

    socket =
      socket
      |> assign(:notification_groups, notification_groups)
      |> assign(:current_page_size, "10")
      |> assign(:stats, calculate_stats())

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    page_size =
      params
      |> Map.get("page_size", "10")
      |> String.to_integer()

    {:ok, {alert_descriptions, meta}} =
      AlertDescriptions.list_alert_descriptions_paginated(params, page_size, [
        :user,
        :notification_group
      ])

    {:noreply,
     socket
     |> assign(:meta, meta)
     |> assign(:current_page_size, Integer.to_string(page_size))
     |> stream(:alert_descriptions, alert_descriptions, reset: true)}
  end

  @impl true
  def handle_info({:new_description, alert_description}, socket) do
    alert_description = Notifeye.Repo.preload(alert_description, [:user, :notification_group])

    {:noreply,
     socket
     |> assign(:stats, calculate_stats())
     |> stream_insert(:alert_descriptions, alert_description, at: 0)}
  end

  @impl true
  def handle_info({:updated_description, alert_description}, socket) do
    # recalculate stats and re-insert the description
    {:noreply,
     socket
     |> assign(:stats, calculate_stats())
     |> stream_insert(:alert_descriptions, alert_description)}
  end

  # : re-fetch data if one is removed, else the table page will
  # not be correct

  @impl true
  def handle_event("update-filter", %{"filters" => filters}, socket) do
    socket = assign(socket, :loading, true)

    # handle page_size separately from filters
    {page_size, filter_params} = Map.pop(filters, "page_size")

    # filter parameters
    filter_query_params =
      filter_params
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Enum.with_index()
      |> Enum.flat_map(&build_filter_param/1)

    # add page_size if provided
    params =
      if page_size && page_size != "" do
        [{"page_size", page_size} | filter_query_params]
      else
        filter_query_params
      end

    {:noreply,
     socket
     |> push_patch(to: ~p"/admin/alert-descriptions?#{params}")}
  end

  @impl true
  def handle_event("export", _params, socket) do
    # implement export functionalitty to a json file
    {:noreply, put_flash(socket, :info, "Export functionality coming soon")}
  end

  defp build_filter_param({{key, value}, index}) do
    {op, final_value} =
      case key do
        "pattern" -> {"ilike", "#{value}"}
        _ -> {"==", value}
      end

    [
      {"filters[#{index}][field]", key},
      {"filters[#{index}][op]", op},
      {"filters[#{index}][value]", final_value}
    ]
  end

  defp page_size_options do
    [
      {"5", "5"},
      {"10", "10"},
      {"20", "20"},
      {"50", "50"},
      {"100", "100"}
    ]
  end

  defp calculate_stats do
    # this is inside a function in case something else is needed on
    # this function
    AlertDescriptions.statistics()
  end
end
