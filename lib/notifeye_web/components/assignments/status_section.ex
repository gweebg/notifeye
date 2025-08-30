defmodule NotifeyeWeb.Components.Assignments.StatusSection do
  @moduledoc """
  Component for displaying assignment status cards.

  Shows different status information based on assignment status and user role.
  """

  use NotifeyeWeb, :live_component

  import NotifeyeWeb.Components.Cards.StatusCard

  def render(assigns) do
    ~H"""
    <section>
      <div :if={@meta.show_status_cards} class="flex flex-col md:flex-row gap-4 w-full">
        <%!-- Assigned User Card --%>
        <.status_card title="Assigned User" description={user_description(@assignment)}>
          <div class="flex items-center gap-2">
            <.icon name="hero-user" class="size-5" />
            <span class="font-medium">
              {@assignment.user.username || @assignment.user.email}
            </span>
          </div>
        </.status_card>

        <%!-- Status Card  --%>
        <.status_card title="Assignment Status" description={status_description(@assignment)}>
          <div class={[
            "badge badge-lg",
            badge_color(@assignment.status)
          ]}>
            {String.capitalize(to_string(@assignment.status))}
          </div>
        </.status_card>

        <%!-- Points Card (Open) --%>
        <.status_card
          :if={@assignment.status == :open}
          title="Your Standing"
          description={standing_description(@meta)}
        >
          <% color = if @meta.can_recover, do: "text-success", else: "text-error"
          sign = if @meta.can_recover, do: "+", else: "-" %>

          <div class="size-8 rounded-full flex items-center justify-center gap-2 text-lg">
            {@current_scope.user.standing}
            <span class={"#{color} text-bold"}>{sign}</span>
            <span class={"#{color} text-bold"}>
              {@meta.recoverable_standing}
            </span>
          </div>
        </.status_card>

        <%!-- Points Card (Closed) --%>
        <.status_card
          :if={@assignment.status == :closed}
          title="Your Standing"
          description={closed_standing_description(@assignment)}
        >
          <% color =
            if @assignment.metadata.change_action == :increase,
              do: "text-success",
              else: "text-error"

          sign = if @assignment.metadata.change_action == :increase, do: "+", else: "-" %>

          <div class="size-8 rounded-full flex items-center justify-center gap-2 text-lg">
            {@current_scope.user.standing}
            <span class={"#{color} text-bold"}>{sign}</span>
            <span class={"#{color} text-bold"}>
              {@assignment.metadata.change_amount}
            </span>
          </div>
        </.status_card>

        <%!-- Frequency Card --%>
        <.status_card title="Frequency" description={frequency_description(@assignment)}>
          <% {color_class, text} = recurrency_card_style(@assignment.metadata.recurrent) %>
          <div class="flex flex-row justify-center items-center">
            <.icon name="hero-arrow-path" class={"size-6 #{color_class}"} />
            <span class={"ml-2 font-semibold #{color_class}"}>
              {text}
            </span>
          </div>
        </.status_card>

        <%!-- Time Remaining --%>
        <.status_card
          :if={@assignment.status == :open}
          title="Time Remaining"
          description="Acknowledgment window"
        >
          <div
            id="countdown"
            class="text-lg font-bold"
            phx-hook="Countdown"
            data-seconds={@meta.time_left}
          >
            <span class="loading loading-spinner loading-md"></span>
          </div>
        </.status_card>
      </div>
    </section>
    """
  end

  # Helper functions

  defp user_description(%{user: %{username: username, email: email}}) when not is_nil(username) do
    email
  end

  defp user_description(%{user: %{email: _email}}) do
    "User account"
  end

  defp status_description(%{status: :open, inserted_at: inserted_at}) do
    Calendar.strftime(inserted_at, "%Y-%m-%d %H:%M")
  end

  defp status_description(%{status: :closed, metadata: %{closed_at: closed_at}}) do
    Calendar.strftime(closed_at, "%Y-%m-%d %H:%M")
  end

  defp status_description(%{status: :expired, inserted_at: inserted_at}) do
    "Expired on #{Calendar.strftime(inserted_at, "%Y-%m-%d %H:%M")}"
  end

  defp status_description(%{status: :unassigned, inserted_at: inserted_at}) do
    "Created on #{Calendar.strftime(inserted_at, "%Y-%m-%d %H:%M")}"
  end

  defp standing_description(%{can_recover: true, recoverable_standing: points}) do
    "#{points} point(s) can be restored"
  end

  defp standing_description(_meta) do
    "If acknowledged right now"
  end

  defp closed_standing_description(%{metadata: %{change_action: :increase, change_amount: amount}}) do
    "Restored #{amount} point(s) to your standing"
  end

  defp closed_standing_description(%{metadata: %{change_action: :decrease, change_amount: amount}}) do
    "Lost #{amount} points"
  end

  defp frequency_description(%{metadata: %{recurrent: true}}) do
    "3+ times in 10 days interval"
  end

  defp frequency_description(%{metadata: %{recurrent: false}}) do
    "3 or less in 10 days interval"
  end

  defp recurrency_card_style(true), do: {"text-error", "Recurrent"}
  defp recurrency_card_style(_status), do: {"text-success", "Non Recurrent"}

  defp badge_color(:open), do: "badge-info"
  defp badge_color(:closed), do: "badge-success"
  defp badge_color(:expired), do: "badge-error"
  defp badge_color(:unassigned), do: "badge-warning"
  defp badge_color(_), do: ""
end
