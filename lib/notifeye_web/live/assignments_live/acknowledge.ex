defmodule NotifeyeWeb.AssignmentsLive.Acknowledge do
  @moduledoc false

  use NotifeyeWeb, :live_view

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

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       acknowledgment_phrase: "",
       submitting: false
     )}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    case AlertAssignments.get_alert_assignment(socket.assigns.current_scope, id) do
      %AlertAssignment{} = assignment ->
        time_left = calculate_time_left(assignment)

        can_recover_points =
          assignment.metadata.recurrent == false &&
            assignment.status == :open &&
            time_left > 0

        meta = %{
          is_recurrent: assignment.metadata.recurrent,
          recoverable_standing: calculate_potential_points(assignment),
          can_recover: can_recover_points,
          time_left: time_left
        }

        socket =
          socket
          |> assign(:assignment, assignment)
          |> assign(:meta, meta)
          |> assign(:required_phrase, Enum.random(@phrase_list))
          |> assign(:assignment_closed, assignment.status == :closed)

        {:noreply, socket}

      nil ->
        {:noreply,
         socket |> put_flash(:error, "The assignment doesn't exist.") |> push_navigate(~p"/")}
    end
  end

  @impl true
  def handle_event("validate", %{"acknowledgment_phrase" => phrase}, socket) do
    {:noreply, assign(socket, acknowledgment_phrase: phrase)}
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

  defp acknowledge_assignment(socket) do
    socket = assign(socket, submitting: true)
    %{assignment: assignment, current_scope: scope} = socket.assigns

    case AlertAssignments.acknowledge_assignment(scope, assignment) do
      {:ok, new_standing, restored} ->
        message =
          if restored do
            "Assignment acknowledged successfully! Your current standing is #{new_standing}."
          else
            "Assignment acknowledged successfully."
          end

        {:noreply,
         socket
         |> put_flash(:info, message)
         |> push_navigate(to: ~p"/")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(submitting: false)
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

  # todo:
  # update acknowledge logic to use :expiry_limit as the time
  # oban job to check expired assignments and set their status to :expired automatically
end
