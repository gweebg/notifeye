defmodule NotifeyeWeb.Components.Assignments.AlertDetails do
  @moduledoc """
  Component for displaying alert information.

  Reusable component that shows all alert details including metadata, samples, etc.
  """

  use NotifeyeWeb, :live_component

  def render(assigns) do
    ~H"""
    <section class="card bg-base-100 shadow-sm">
      <div class="card-body">
        <%!-- Alert Header --%>
        <h3 class="card-title mb-4 flex flex-row justify-between">
          <p>
            Alert Details
            <.link navigate={~p"/alerts/#{@assignment.alert.id}"}>
              <.icon name="hero-arrow-top-right-on-square mb-1" class="w-4 h-4" />
            </.link>
          </p>
          <span class="badge badge-sm badge-soft">
            {Calendar.strftime(@assignment.alert.start, "%d %b %Y at %H:%M")}
          </span>
        </h3>

        <div class="flex flex-col lg:flex-row gap-6">
          <div class="flex-1 space-y-4">
            <%!-- Alert ID --%>
            <div class="space-y-2">
              <label class="label">
                <span class="label-text font-medium">Event ID</span>
              </label>
              <p class="text-sm">{@assignment.alert.logz_id}</p>
            </div>
            <%!-- Alert Title --%>
            <div class="space-y-2">
              <label class="label">
                <span class="label-text font-medium">Alert Title</span>
              </label>
              <p class="text-base-content">{@assignment.alert.alert_title}</p>
            </div>
          </div>

          <div class="flex-1 space-y-4">
            <%!-- Alert Severity --%>
            <div class="flex flex-col gap-2">
              <label class="label">
                <span class="label-text font-medium">Severity</span>
              </label>
              <div class={[
                "badge",
                severity_badge_class(@assignment.alert.alert_severity)
              ]}>
                {String.capitalize(@assignment.alert.alert_severity)}
              </div>
            </div>

            <div class="space-y-2">
              <label class="label">
                <span class="label-text font-medium">Tags</span>
              </label>
              <div class="flex flex-wrap gap-2">
                <%= for tag <- @assignment.alert.alert_tags do %>
                  <div class="badge badge-neutral badge-sm">
                    {tag}
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-4 space-y-2">
          <label class="label">
            <span class="label-text font-medium">Description</span>
          </label>
          <p>{@assignment.alert.alert_description}</p>
        </div>

        <%= if @assignment.alert.alert_event_samples do %>
          <div class="mt-4 space-y-2">
            <label class="label">
              <span class="label-text font-medium">Event Samples</span>
            </label>
            <div class="card bg-base-200 text-sm p-4">
              <pre class="whitespace-pre-wrap"><code>{@assignment.alert.alert_event_samples}</code></pre>
            </div>
          </div>
        <% end %>
      </div>
    </section>
    """
  end

  # Helper functions

  defp severity_badge_class("high"), do: "badge-error"
  defp severity_badge_class("medium"), do: "badge-warning"
  defp severity_badge_class("low"), do: "badge-success"
  defp severity_badge_class(_), do: "badge-neutral"
end
