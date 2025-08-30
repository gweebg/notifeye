defmodule NotifeyeWeb.AssignmentsLive.Acknowledge do
  @moduledoc false

  use NotifeyeWeb, :live_view
  use NotifeyeWeb.Components

  alias Notifeye.AlertAssignments
  alias Notifeye.AlertAssignments.AlertAssignment
  alias Notifeye.Monitoring

  @phrase_list [
    "I confirm that I have carefully reviewed this alert and fully understand the details of the situation.",
    "I acknowledge having read and understood this alert, and I am aware of the circumstances it describes.",
    "I have gone through the contents of this alert and recognize the nature of the situation it refers to.",
    "I confirm that I have read this alert thoroughly and comprehend the situation as outlined.",
    "I acknowledge receipt of this alert and affirm that I understand the context and implications of the situation."
  ]

  # todo today:
  # states: :expired, :unassigned
  # if expired don't allow for ack
  # if unassigned dont't show the form, allow re-assignment, triggers new notification job
  # if admin, allow admin to see and ack for another user (how to deal with navbar?)
  # add name to alert description

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, acknowledgment_phrase: "", transfer_user_id: nil)}
  end

  @impl true
  def handle_params(%{"id" => _id}, _, socket) do
    case socket.assigns.resource do
      %AlertAssignment{} = assignment ->
        {:noreply,
         socket
         |> assign(:assignment, assignment)
         |> assign(:meta, build_meta(assignment, socket.assigns.current_scope))
         |> assign(:required_phrase, Enum.random(@phrase_list))
         |> assign_available_users(assignment, socket.assigns.current_scope)}

      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "The assignment doesn't exist.")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("validate", %{"acknowledgment_phrase" => phrase}, socket) do
    {:noreply, assign(socket, acknowledgment_phrase: phrase)}
  end

  @impl true
  def handle_event("validate_transfer", %{"transfer_user_id" => user_id}, socket) do
    {:noreply, assign(socket, transfer_user_id: user_id)}
  end

  @impl true
  def handle_event("acknowledge", _map, %{assigns: %{assignment: %{status: :closed}}} = socket) do
    {:noreply, put_flash(socket, :error, "This assignment is already closed")}
  end

  @impl true
  def handle_event(
        "acknowledge",
        %{"acknowledgment_phrase" => phrase},
        %{assigns: assigns} = socket
      ) do
    trimmed_phrase = String.trim(phrase)

    if trimmed_phrase != assigns.required_phrase do
      {:noreply, put_flash(socket, :error, "Please enter the exact acknowledgment phrase.")}
    else
      acknowledge_assignment(socket)
    end
  end

  @impl true
  def handle_event("transfer_assignment", %{"transfer_user_id" => user_id}, socket) do
    %{assignment: assignment, current_scope: scope} = socket.assigns

    case AlertAssignments.transfer_assignment(scope, assignment, user_id) do
      {:ok, updated_assignment} ->
        {:noreply,
         socket
         |> put_flash(:success, "Assignment transferred successfully.")
         |> assign(:assignment, updated_assignment)
         |> assign(:meta, build_meta(updated_assignment, scope))
         |> assign_available_users(updated_assignment, scope)}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to transfer assignment: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("force_acknowledge", _params, socket) do
    %{assignment: assignment, current_scope: scope} = socket.assigns

    case AlertAssignments.force_acknowledge_assignment(scope, assignment) do
      {:ok, result, new_standing, restored} ->
        message =
          if restored do
            "Assignment force acknowledged successfully! User's current standing is #{new_standing}."
          else
            "Assignment force acknowledged successfully."
          end

        {:noreply,
         socket
         |> put_flash(:info, message)
         |> assign(:assignment, result)
         |> assign(:meta, build_meta(result, scope))}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to force acknowledge assignment: #{inspect(reason)}")}
    end
  end

  # Helper Functions

  defp assign_available_users(socket, assignment, %{user: %{role: :admin}}) do
    available_users = AlertAssignments.list_users_except(assignment.user_id)
    assign(socket, :available_users, available_users)
  end

  defp assign_available_users(socket, _assignment, _scope) do
    assign(socket, :available_users, [])
  end

  defp build_meta(%AlertAssignment{} = assignment, scope) do
    time_left = calculate_time_left(assignment)

    can_recover_points =
      assignment.metadata.recurrent == false &&
        assignment.status == :open &&
        time_left > 0

    %{
      is_recurrent: assignment.metadata.recurrent,
      recoverable_standing: calculate_potential_points(assignment),
      can_recover: can_recover_points,
      time_left: time_left,
      show_status_cards: show_status_cards?(assignment, scope),
      show_transfer_form: show_transfer_form?(assignment, scope),
      show_force_acknowledge: show_force_acknowledge?(assignment, scope),
      show_user_acknowledgment: show_user_acknowledgment?(assignment, scope),
      alert_message: get_alert_message(assignment)
    }
  end

  # Status and role helper functions

  defp show_status_cards?(%{status: :unassigned}, _scope), do: false
  defp show_status_cards?(_assignment, _scope), do: true

  defp show_transfer_form?(%{status: status}, %{user: %{role: :admin}})
       when status in [:open, :unassigned],
       do: true

  defp show_transfer_form?(_assignment, _scope), do: false

  defp show_force_acknowledge?(%{status: status}, %{user: %{role: :admin}})
       when status in [:open, :expired],
       do: true

  defp show_force_acknowledge?(_assignment, _scope), do: false

  defp show_user_acknowledgment?(%{status: :open, user_id: user_id}, %{user: %{id: user_id}}),
    do: true

  defp show_user_acknowledgment?(_assignment, _scope), do: false

  defp get_alert_message(%{status: :open}),
    do:
      {:info,
       "The eligibility for restoration depends the recurrency status of the alert and time of acknowledge. You have up to 24 hours since the assignment to acknowledge the alert."}

  defp get_alert_message(%{status: :expired}),
    do: {:warning, "This assignment has expired due to lack of acknowledgment within 24 hours."}

  defp get_alert_message(_assignment), do: nil

  defp acknowledge_assignment(socket) do
    %{assignment: assignment, current_scope: scope} = socket.assigns

    case AlertAssignments.acknowledge_assignment(scope, assignment) do
      {:ok, result, new_standing, restored} ->
        message =
          if restored do
            "Assignment acknowledged successfully! Your current standing is #{new_standing}."
          else
            "Assignment acknowledged successfully."
          end

        {
          :noreply,
          socket
          |> put_flash(:info, message)
          |> assign(:assignment, result)
          |> assign(:meta, build_meta(result, scope))
        }

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to acknowledge assignment: #{inspect(reason)}")}
    end
  end

  defp calculate_potential_points(%{alert: %{alert_severity: severity}}) do
    Monitoring.calculate_standing_amount_by_severity(severity)
  end

  defp calculate_time_left(assignment) do
    created_at = assignment.inserted_at
    deadline = DateTime.add(created_at, 24, :hour)
    now = DateTime.utc_now()

    if DateTime.compare(now, deadline) == :lt do
      DateTime.diff(deadline, now, :second)
    else
      0
    end
  end
end
