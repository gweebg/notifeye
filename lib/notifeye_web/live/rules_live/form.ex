defmodule NotifeyeWeb.RulesLive.Form do
  @moduledoc false
  use NotifeyeWeb, :live_view

  alias Notifeye.AlertDescriptions
  alias Notifeye.Rules
  alias Notifeye.AlertDescriptions.AlertDescription.Rule
  alias Notifeye.AlertDescriptions.Rule.Fields
  alias Notifeye.Notifications.Dispatcher

  @field_labels %{
    "alert_title" => "Alert Title",
    "alert_description" => "Alert Description",
    "alert_severity" => "Alert Severity",
    "alert_tags" => "Alert Tags",
    "start" => "Start Time",
    "end" => "End Time",
    "inserted_at" => "Created At"
  }

  @operator_labels %{
    "is" => "equals",
    "is_not" => "does not equal",
    "matches" => "matches (regex)",
    "contains" => "contains",
    "does_not_contain" => "does not contain",
    "starts_with" => "starts with",
    "ends_with" => "ends with",
    "include" => "includes",
    "exclude" => "excludes",
    "after_datetime" => "is after (datetime)",
    "before_datetime" => "is before (datetime)",
    "after_time" => "is after (time)",
    "before_time" => "is before (time)"
  }

  @placeholders %{
    "alert_severity" => "info, low, medium, high, severe",
    "alert_tags" => "production",
    "start" => "14:30:00",
    "end" => "22:00:00",
    "inserted_at" => "2024-08-09T10:00:00Z"
  }

  # todo: future improvements
  # todo: add different field types based on the field type
  # todo: better selectors with autocomplete
  # todo: refactor the logic

  # Mount

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    {:ok, assign_defaults(socket, id, params["rule_id"])}
  end

  # Handle Events

  @impl true
  def handle_event("validate", %{"rule" => rule_params}, socket) do
    base_rule =
      case socket.assigns.rule do
        nil -> %Rule{alert_description_id: socket.assigns.alert_description.id}
        rule -> %Rule{alert_description_id: socket.assigns.alert_description.id, id: rule.id}
      end

    changeset =
      base_rule
      |> Rules.change_rule_building(rule_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("toggle_provider", %{"provider" => provider}, socket) do
    list = socket.assigns.selected_providers

    updated_providers =
      if provider in list, do: List.delete(list, provider), else: [provider | list]

    current_changeset = socket.assigns.form.source
    current_action = Ecto.Changeset.get_field(current_changeset, :action)

    action_value =
      if current_action == :notify do
        Enum.join(updated_providers, ",")
      else
        Ecto.Changeset.get_field(current_changeset, :action_value)
      end

    # create updated changeset with new action_value
    updated_changeset =
      current_changeset
      |> Ecto.Changeset.put_change(:action_value, action_value)
      |> Map.put(:action, :validate)

    {
      :noreply,
      socket
      |> assign(:selected_providers, updated_providers)
      |> assign(:form, to_form(updated_changeset))
    }
  end

  def handle_event("add_block", _, socket),
    do: {:noreply, update_changeset(socket, &Rule.add_block/1)}

  def handle_event("add_clause", %{"block_index" => idx}, socket),
    do: {:noreply, update_changeset(socket, &Rule.add_clause(&1, String.to_integer(idx)))}

  def handle_event("remove_clause", %{"block_index" => bi, "clause_index" => ci}, socket) do
    block_index = String.to_integer(bi)
    clause_index = String.to_integer(ci)

    current_changeset = socket.assigns.form.source
    rule_blocks = Ecto.Changeset.get_field(current_changeset, :rule_blocks, [])

    total_blocks = length(rule_blocks)
    current_block = Enum.at(rule_blocks, block_index)
    total_clauses_in_block = if current_block, do: length(current_block.clauses || []), else: 0

    # if last clause on a block, remove the block
    changeset_function =
      if total_blocks > 1 and total_clauses_in_block == 1 do
        &Rule.remove_block(&1, block_index)
      else
        &Rule.remove_clause(&1, block_index, clause_index)
      end

    {:noreply, update_changeset(socket, changeset_function)}
  end

  def handle_event("save", %{"rule" => rule_params}, socket) do
    providers =
      socket.assigns.selected_providers
      |> Enum.join(",")

    rule_params =
      rule_params
      |> Map.put("action_value", providers)
      |> Map.put("alert_description_id", socket.assigns.alert_description.id)

    rule = socket.assigns.rule

    case save_rule(rule, rule_params) do
      {:ok, _rule} ->
        action = if rule, do: "updated", else: "created"

        {
          :noreply,
          socket
          |> put_flash(:info, "Rule #{action} successfully")
          |> push_navigate(
            to: ~p"/notifications/rules?description=#{socket.assigns.alert_description.id}"
          )
        }

      {:error, changeset} ->
        {:noreply, socket |> assign(form: to_form(changeset))}
    end
  end

  ## Helpers

  defp save_rule(nil, params), do: Rules.create_rule(params)
  defp save_rule(rule, params), do: Rules.update_rule(rule, params)

  defp assign_defaults(socket, alert_description_id, rule_id) do
    alert_description = AlertDescriptions.get_alert_description!(alert_description_id)
    available_providers = Dispatcher.available_providers()

    {rule, changeset, selected_providers} =
      case rule_id do
        nil ->
          # New rule - start fresh
          base_rule_changeset =
            %Rule{alert_description_id: alert_description.id}
            |> Rules.change_rule_building(%{"action" => "notify"})
            |> Rule.add_block()

          {nil, base_rule_changeset, []}

        id ->
          # rebuild the changeset structure like a new rule, avoids
          # the need for handling form params
          rule = Rules.get_rule!(id)

          rule_params = %{
            "name" => rule.name,
            "action" => to_string(rule.action),
            "rule_blocks" => convert_rule_blocks_to_params(rule.rule_blocks)
          }

          base_rule = %Rule{alert_description_id: alert_description.id}
          changeset = Rules.change_rule_building(base_rule, rule_params)
          selected_providers = parse_providers(rule.action_value)

          {rule, changeset, selected_providers}
      end

    socket
    |> assign(:alert_description, alert_description)
    |> assign(:rule, rule)
    |> assign(:form, to_form(changeset))
    |> assign(:available_providers, available_providers)
    |> assign(:selected_providers, selected_providers)
    |> assign(:show_debug, false)
  end

  defp update_changeset(socket, fun) do
    changeset =
      socket.assigns.form.source
      |> fun.()
      |> Map.put(:action, :validate)

    assign(socket, form: to_form(changeset))
  end

  defp parse_providers(nil), do: []
  defp parse_providers(""), do: []

  defp parse_providers(val),
    do: val |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

  # convert database rule_blocks back to form params structure
  defp convert_rule_blocks_to_params(rule_blocks) do
    rule_blocks
    |> Enum.with_index()
    |> Map.new(fn {block, block_index} ->
      clauses_params =
        block.clauses
        |> Enum.with_index()
        |> Map.new(fn {clause, clause_index} ->
          {to_string(clause_index),
           %{
             "field" => clause.field,
             "operator" => clause.operator,
             "value" => clause.value
           }}
        end)

      {to_string(block_index), %{"clauses" => clauses_params}}
    end)
  end

  # Public for form selects

  def field_options,
    do: Fields.valid_fields() |> Enum.map(&{Map.get(@field_labels, &1, &1), &1})

  def operator_options(nil), do: []

  def operator_options(field),
    do: Fields.valid_operators(field) |> Enum.map(&{Map.get(@operator_labels, &1, &1), &1})

  def value_placeholder(field),
    do: Map.get(@placeholders, field, "Enter value")
end
