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

  @impl true
  def handle_params(params, _url, socket) do
    page_size =
      params
      |> Map.get("page_size", "10")

    filters = filters_from_params(params)

    {:ok, {alert_descriptions, meta}} =
      AlertDescriptions.list_alert_descriptions(params,
        page_size: page_size,
        preload: [:user, :notification_group],
        no_ignored: true
      )

    {:noreply,
     socket
     |> assign(:meta, meta)
     |> assign(:current_page_size, page_size)
     |> assign(:current_params, params)
     |> assign(:filters, filters)
     |> stream(:alert_descriptions, alert_descriptions, reset: true)}
  end

  @impl true
  def handle_info({:new_description, _alert_description}, socket) do
    {:noreply, refresh(socket)}
  end

  @impl true
  def handle_info({:updated_description, _alert_description}, socket) do
    {:noreply, refresh(socket)}
  end

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
     |> push_patch(to: ~p"/admin/descriptions?#{params}")}
  end

  @impl true
  def handle_event("export", _params, socket) do
    # todo: implement export functionalitty to a json file
    {:noreply, put_flash(socket, :info, "Export functionality coming soon")}
  end

  defp refresh(socket) do
    params = socket.assigns.current_params || %{}

    {:ok, {alert_descriptions, meta}} =
      AlertDescriptions.list_alert_descriptions(params,
        page_size: socket.assigns.current_page_size,
        preload: [:user, :notification_group],
        no_ignored: true
      )

    socket
    |> assign(:stats, calculate_stats())
    |> assign(:meta, meta)
    |> stream(:alert_descriptions, alert_descriptions, reset: true)
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

  defp filters_from_params(params) do
    desired_fields = ~w(state verified id_search notification_group pattern)

    filters =
      params
      |> Map.get("filters", %{})
      |> Map.values()
      |> Enum.reduce(%{}, fn %{"field" => field, "value" => value}, acc ->
        if field in desired_fields, do: Map.put(acc, field, value), else: acc
      end)

    complete_filters =
      for field <- desired_fields, into: %{} do
        {field, Map.get(filters, field, "")}
      end

    Map.put(complete_filters, "page_size", Map.get(params, "page_size", 10))
  end
end
