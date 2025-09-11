defmodule NotifeyeWeb.Components.Dashboard.NotificationStats do
  @moduledoc """
  Card component with general statistics and latest information
  relative to sent notifications.
  """
  use NotifeyeWeb, :live_component

  @doc """
  Renders a section containing generic alert statistics as well as
  listing recent alerts.

  ## Attributes

  * `time_window` - Defines how back the queries go.
  * `stats` - A map containing the displayed statistics of the alerts.
  """

  attr :time_window, :string, default: "Undefined"
  attr :count_by_state, :map, default: %{}
  attr :notifications, :list, default: []

  def render(assigns) do
    ~H"""
    <section class="card bg-base-100 border border-base-200 shadow-sm">
      <div class="card-body">
        <%!-- Header --%>
        <h2 class="card-title flex flex-row mb-4 justify-between">
          <span class="flex flex-row items-center gap-2">
            <.icon name="hero-bell" class="size-5" /> Notifications
          </span>
          <span class="text-xs text-base-content/60 font-normal">
            {@time_window}
          </span>
        </h2>

        <%!-- Base Stats --%>
        <div class="grid grid-cols-2 gap-4 mb-6">
          <div class="stat bg-success/10 rounded-lg p-4">
            <div class="stat-figure">
              <.icon name="hero-check-circle" class="size-6 text-success" />
            </div>
            <div class="stat-title">Sent</div>
            <div class="stat-value text-success">
              {safe(@count_by_state, :completed, 0) + safe(@count_by_state, :cancelled, 0)}
            </div>
          </div>
          <div class="stat bg-error/10 rounded-lg p-4">
            <div class="stat-figure">
              <.icon name="hero-x-circle" class="size-6 text-error" />
            </div>
            <div class="stat-title">Failed</div>
            <div class="stat-value text-error">
              {safe(@count_by_state, :discarded, 0)}
            </div>
          </div>
        </div>

        <%!-- Recent Notifications --%>
        <div class="overflow-x-auto">
          <table class="table table-xs">
            <thead>
              <tr>
                <th>User</th>
                <th>Method</th>
                <th>Status</th>
                <th>Time</th>
              </tr>
            </thead>
            <tbody>
              <tr :if={Enum.empty?(@notifications)}>
                <td colspan="3" class="text-center text-base-content/50 py-8">
                  Recent notifications will appear here...
                </td>
              </tr>

              <tr
                :for={n <- @notifications}
                phx-click="navigate_notification"
                phx-value-id={n.id}
                class="cursor-pointer hover:bg-base-200"
              >
                <td>{n.state}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>
    """
  end

  defp safe(nil, _key, default), do: default
  defp safe(map, key, default), do: Map.get(map, key, default)
end
