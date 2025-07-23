defmodule NotifeyeWeb.AssignmentsLive.Acknowledge do
  @moduledoc false

  use NotifeyeWeb, :live_view

  alias Notifeye.AlertAssignments
  alias Notifeye.AlertAssignments.AlertAssignment
  alias Notifeye.Monitoring

  @required_phrase "I acknowledge that I have reviewed this alert and understand the situation."

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, acknowledgment_phrase: "", submitting: false)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    case AlertAssignments.get_alert_assignment(socket.assigns.current_scope, id) do
      %AlertAssignment{} = assignment ->
        assignment = preload_assignment_data(assignment)

        is_recurrent =
          AlertAssignments.recurrent?(
            socket.assigns.current_scope,
            assignment.alert_description_id
          )

        time_left = calculate_time_left(assignment)
        potential_points = calculate_potential_points(assignment)
        can_recover_points = can_recover_points?(assignment, is_recurrent, time_left)

        socket =
          socket
          |> assign(:assignment, assignment)
          |> assign(:is_recurrent, is_recurrent)
          |> assign(:potential_points, potential_points)
          |> assign(:time_left, time_left)
          |> assign(:can_recover_points, can_recover_points)
          |> assign(:required_phrase, @required_phrase)
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
  def handle_event("acknowledge", %{"acknowledgment_phrase" => phrase}, socket) do
    required_phrase = @required_phrase
    assignment = socket.assigns.assignment

    cond do
      assignment.status == :closed ->
        {:noreply, put_flash(socket, :error, "This assignment is already closed")}

      String.trim(phrase) != required_phrase ->
        {:noreply, put_flash(socket, :error, "Please enter the exact acknowledgment phrase")}

      true ->
        socket = assign(socket, submitting: true)

        case AlertAssignments.acknowledge_assignment(socket.assigns.current_scope, assignment) do
          {:ok, _new_standing, restored} ->
            message =
              if restored do
                "Assignment acknowledged successfully! Points have been restored to your account."
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
  end

  defp preload_assignment_data(assignment) do
    assignment
    |> Notifeye.Repo.preload([:alert, :alert_description, :user])
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

  defp can_recover_points?(assignment, is_recurrent, time_left) do
    assignment.status == :open and not is_recurrent and time_left > 0
  end

  # afazer:
  # fix ~p
  # refactor ack handle_event
  # refactor heex
  # automatically set assignment to expired if 24 over (oban)
  # heex status for :expired

  # defp phrases_match?(input, required) do
  #   String.trim(input) == String.trim(required)
  # end

  # defp can_acknowledge?(socket) do
  #   assignment = socket.assigns.assignment
  #   phrase = socket.assigns.acknowledgment_phrase
  #   required_phrase = socket.assigns.required_phrase

  #   assignment.status == :open and
  #     not socket.assigns.submitting and
  #     phrases_match?(phrase, required_phrase)
  # end
end
