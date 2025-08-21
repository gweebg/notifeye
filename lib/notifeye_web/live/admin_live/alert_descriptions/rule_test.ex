defmodule NotifeyeWeb.AdminLive.AlertDescriptions.RuleTest do
  @moduledoc false

  use NotifeyeWeb, :live_view

  alias Notifeye.AlertDescriptions
  alias Notifeye.Rules
  alias Notifeye.AlertDescriptions.AlertDescription.Rule
  alias Notifeye.AlertDescriptions.Rule.Fields

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} current_path={@current_path}>
      <.header>
        Rule Test for "{@alert_description.id}"
        <:subtitle>Test the rule building form with dynamic blocks and clauses.</:subtitle>
      </.header>

      <.form for={@form} id="rule-test-form" phx-change="validate" phx-submit="save">
        <div class="space-y-6">
          <!-- Rule basic info -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.input
              field={@form[:name]}
              type="text"
              label="Rule Name"
              placeholder="My notification rule"
            />
            <.input
              field={@form[:action]}
              type="select"
              label="Action"
              options={[{"Notify", "notify"}, {"Do Nothing", "nothing"}]}
            />
          </div>
          
    <!-- Action value (shown only when action is notify) -->
          <div :if={@form[:action].value == "notify"} class="grid grid-cols-1">
            <.input
              field={@form[:action_value]}
              type="text"
              label="Notification Methods"
              placeholder="email,slack,webhook"
            />
            <p class="text-sm text-gray-600 mt-1">Comma-separated list of notification methods</p>
          </div>
          
    <!-- Rule Blocks -->
          <div class="space-y-4">
            <div class="flex items-center justify-between">
              <h3 class="text-lg font-medium">Rule Conditions</h3>
              <.button type="button" phx-click="add_block">
                Add OR Block
              </.button>
            </div>

            <div class="space-y-6">
              <.inputs_for :let={block_form} field={@form[:rule_blocks]}>
                <div class="border border-gray-200 rounded-lg p-4 space-y-4">
                  <div class="flex items-center justify-between">
                    <h4 class="font-medium text-gray-700">Block {block_form.index + 1}</h4>
                    <div class="flex gap-2">
                      <.button
                        type="button"
                        phx-click="add_clause"
                        phx-value-block_index={block_form.index}
                      >
                        Add AND Clause
                      </.button>
                      <.button
                        :if={length(@form[:rule_blocks].value) > 1}
                        type="button"
                        phx-click="remove_block"
                        phx-value-block_index={block_form.index}
                      >
                        Remove Block
                      </.button>
                    </div>
                  </div>
                  
    <!-- Rule Clauses -->
                  <div class="space-y-3">
                    <.inputs_for :let={clause_form} field={block_form[:clauses]}>
                      <div class="grid grid-cols-1 md:grid-cols-4 gap-3 items-end">
                        <.input
                          field={clause_form[:field]}
                          type="select"
                          label="Field"
                          options={field_options()}
                        />
                        <.input
                          field={clause_form[:operator]}
                          type="select"
                          label="Operator"
                          options={operator_options(clause_form[:field].value)}
                        />
                        <.input
                          field={clause_form[:value]}
                          type="text"
                          label="Value"
                          placeholder={value_placeholder(clause_form[:field].value)}
                        />
                        <.button
                          :if={length(block_form[:clauses].value) > 1}
                          type="button"
                          phx-click="remove_clause"
                          phx-value-block_index={block_form.index}
                          phx-value-clause_index={clause_form.index}
                        >
                          Remove
                        </.button>
                      </div>
                    </.inputs_for>
                  </div>
                </div>
              </.inputs_for>
            </div>
          </div>
          
    <!-- Form actions -->
          <div class="flex gap-3">
            <.button phx-disable-with="Saving..." variant="primary">Save Rule</.button>
            <.button navigate={~p"/descriptions/#{@alert_description.id}"}>
              Cancel
            </.button>
            <.button type="button" phx-click="toggle_debug">
              Toggle Debug
            </.button>
          </div>
        </div>
      </.form>
      
    <!-- Debug info (remove in production) -->
      <div :if={@show_debug} class="mt-8 p-4 bg-gray-50 rounded">
        <h4 class="font-medium mb-2">Debug Info:</h4>
        <pre class="text-xs overflow-auto">{inspect(@form.source, pretty: true)}</pre>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    alert_description = AlertDescriptions.get_alert_description!(id)
    changeset = Rules.new_rule_changeset(alert_description.id)

    {:ok,
     socket
     |> assign(:alert_description, alert_description)
     |> assign(:form, to_form(changeset))
     |> assign(:show_debug, false)}
  end

  @impl true
  def handle_event("validate", %{"rule" => rule_params}, socket) do
    changeset =
      %Rule{alert_description_id: socket.assigns.alert_description.id}
      |> Rules.change_rule_building(rule_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("add_block", _params, socket) do
    changeset =
      socket.assigns.form.source
      |> Rule.add_block()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("remove_block", %{"block_index" => block_index}, socket) do
    changeset =
      socket.assigns.form.source
      |> Rule.remove_block(String.to_integer(block_index))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("add_clause", %{"block_index" => block_index}, socket) do
    changeset =
      socket.assigns.form.source
      |> Rule.add_clause(String.to_integer(block_index))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event(
        "remove_clause",
        %{"block_index" => block_index, "clause_index" => clause_index},
        socket
      ) do
    changeset =
      socket.assigns.form.source
      |> Rule.remove_clause(String.to_integer(block_index), String.to_integer(clause_index))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"rule" => rule_params}, socket) do
    # Add the alert_description_id to the params
    rule_params_with_id =
      Map.put(rule_params, "alert_description_id", socket.assigns.alert_description.id)

    case Rules.create_rule(rule_params_with_id) do
      {:ok, _rule} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rule created successfully")
         |> push_navigate(to: ~p"/descriptions/#{socket.assigns.alert_description.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("toggle_debug", _params, socket) do
    {:noreply, assign(socket, show_debug: !socket.assigns.show_debug)}
  end

  # Helper functions for form options
  defp field_options do
    Fields.valid_fields()
    |> Enum.map(&{field_label(&1), &1})
  end

  defp field_label("alert_title"), do: "Alert Title"
  defp field_label("alert_description"), do: "Alert Description"
  defp field_label("alert_severity"), do: "Alert Severity"
  defp field_label("alert_tags"), do: "Alert Tags"
  defp field_label("start"), do: "Start Time"
  defp field_label("end"), do: "End Time"
  defp field_label("inserted_at"), do: "Created At"
  defp field_label(field), do: field

  defp operator_options(nil), do: []

  defp operator_options(field) do
    Fields.valid_operators(field)
    |> Enum.map(&{operator_label(&1), &1})
  end

  defp operator_label("is"), do: "equals"
  defp operator_label("is_not"), do: "does not equal"
  defp operator_label("matches"), do: "contains"
  defp operator_label("include"), do: "includes"
  defp operator_label("doesnt_include"), do: "does not include"
  defp operator_label("after"), do: "is after"
  defp operator_label("before"), do: "is before"
  defp operator_label("equal"), do: "equals (time)"
  defp operator_label(op), do: op

  defp value_placeholder("alert_severity"), do: "low, medium, high"
  defp value_placeholder("alert_tags"), do: "production"
  defp value_placeholder("start"), do: "14:30:00"
  defp value_placeholder("end"), do: "22:00:00"
  defp value_placeholder("inserted_at"), do: "2024-08-09T10:00:00Z"
  defp value_placeholder(_), do: "Enter value"
end
