defmodule NotifeyeWeb.RulesLive.Index do
  @moduledoc false

  use NotifeyeWeb, :live_view

  alias Notifeye.{AlertDescriptions, Rules}
  alias Notifeye.AlertDescriptions.AlertDescription

  use NotifeyeWeb.Components

  @impl true
  def mount(_params, _session, socket) do
    alert_descriptions = AlertDescriptions.list_alert_descriptions()

    socket =
      socket
      |> assign(:alert_descriptions, alert_descriptions)
      |> assign(:selected_description, nil)
      |> assign(:rules, [])
      |> assign(:meta, nil)
      |> assign(:loading, false)
      |> assign(:show_delete_modal, false)
      |> assign(:rule_to_delete, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      with description_id when description_id != nil <- params["description"],
           {parsed_id, ""} <- Integer.parse(description_id),
           %AlertDescription{} = description <-
             AlertDescriptions.get_alert_description(parsed_id) do
        load_rules_for_description(socket, description, params)
      else
        _ -> assign(socket, :selected_description, nil)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_description", %{"description_id" => description_id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/notifications/rules?description=#{description_id}")}
  end

  def handle_event("update-filter", %{"filters" => filters}, socket) do
    current_description_id =
      if socket.assigns.selected_description do
        socket.assigns.selected_description.id
      else
        nil
      end

    params =
      filters
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Enum.with_index()
      |> Enum.flat_map(&build_filter_param/1)

    {:noreply,
     push_patch(socket,
       to: ~p"/notifications/rules?#{params}&description=#{current_description_id}"
     )}
  end

  def handle_event("confirm_delete", %{"rule_id" => rule_id}, socket) do
    case Rules.get_rule(rule_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Rule with id #{rule_id} not found.")}

      rule ->
        socket =
          socket
          |> assign(:rule_to_delete, rule)
          |> assign(:show_delete_modal, true)

        {:noreply, socket}
    end
  end

  def handle_event("cancel_delete", _params, socket) do
    socket =
      socket
      |> assign(:show_delete_modal, false)
      |> assign(:rule_to_delete, nil)

    {:noreply, socket}
  end

  def handle_event("delete_rule", _params, socket) do
    rule = socket.assigns.rule_to_delete

    with false <- is_nil(rule),
         {:ok, _d} <- Rules.delete_rule(rule) do
      {:noreply,
       socket
       |> clear_delete_state()
       |> put_flash(:info, "Rule deleted successfully!")
       |> refresh_rules()}
    else
      {:error, _changeset} ->
        {:noreply,
         socket
         |> clear_delete_state()
         |> put_flash(:error, "Failed to delete rule")}

      _ ->
        {:noreply, put_flash(socket, :error, "No rule selected for deletion.")}
    end
  end

  def handle_event("toggle_rule", %{"rule_id" => rule_id, "action" => action}, socket) do
    with rule when not is_nil(rule) <- Rules.get_rule(rule_id),
         {:ok, _updated} <- perform_rule_action(rule, action) do
      {:noreply,
       socket
       |> put_flash(:info, "Rule #{action}d successfully.")
       |> refresh_rules()}
    else
      nil ->
        {:noreply, put_flash(socket, :error, "Rule with id #{rule_id} not found.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to #{action} rule.")}
    end
  end

  defp load_rules_for_description(socket, description, params) do
    filters = filters_from_params(params)

    case Rules.list_rules_flop(params, description.id) do
      {:ok, {rules, meta}} ->
        socket
        |> assign(:selected_description, description)
        |> assign(:rules, rules)
        |> assign(:filters, filters)
        |> assign(:meta, meta)
        |> assign(:loading, false)

      {:error, _meta} ->
        socket
        |> assign(:selected_description, description)
        |> assign(:rules, [])
        |> assign(:filters, %{})
        |> assign(:meta, nil)
        |> assign(:loading, false)
        |> put_flash(:error, "Failed to load rules.")
    end
  end

  defp filters_from_params(params) do
    desired_fields = ~w(name active)

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

    complete_filters
  end

  defp build_filter_param({{key, value}, index}) do
    {op, final_value} =
      case key do
        "name" -> {"ilike", "#{value}"}
        _ -> {"==", value}
      end

    [
      {"filters[#{index}][field]", key},
      {"filters[#{index}][op]", op},
      {"filters[#{index}][value]", final_value}
    ]
  end

  defp perform_rule_action(rule, "enable"), do: Rules.enable_rule(rule)
  defp perform_rule_action(rule, "disable"), do: Rules.disable_rule(rule)

  # todo: review
  defp refresh_rules(socket) do
    case socket.assigns.selected_description do
      nil ->
        socket

      description ->
        current_path = get_in(socket.assigns, [:current_path])

        current_params =
          if current_path, do: URI.decode_query(URI.parse(current_path).query || ""), else: %{}

        load_rules_for_description(socket, description, current_params)
    end
  end

  defp clear_delete_state(socket),
    do:
      socket
      |> assign(:show_delete_modal, false)
      |> assign(:rule_to_delete, nil)
end
