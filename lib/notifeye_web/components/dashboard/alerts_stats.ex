defmodule NotifeyeWeb.Components.Dashboard.AlertsStats do
  @moduledoc """
  Card component with general statistics and latest information
  relative to incoming alerts.
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
  attr :stats, :map, default: %{}

  def render(assigns) do
    ~H"""
    <section class="card bg-base-100 border border-base-200 shadow-sm">
      <div class="card-body">
        <%!-- Header --%>
        <h2 class="card-title flex flex-row mb-4 justify-between">
          <span>
            <.icon name="hero-exclamation-triangle" class="w-5 h-5 text-warning" /> Alerts
          </span>
          <span class="text-xs text-base-content/60 font-normal">
            {@time_window}
          </span>
        </h2>

        <%!-- Statistics Cards  --%>
        <div class="grid grid-cols-4 gap-3 mb-6">
          <div class="stat bg-base-200 rounded-lg p-3">
            <div class="stat-title text-xs">Total</div>
            <div class="stat-value text-xl">{safe(@stats, :total_alerts)}</div>
          </div>
          <div class="stat bg-info/10 rounded-lg p-3">
            <div class="stat-title text-xs">Low</div>
            <div class="stat-value text-xl text-info">
              {safe(@stats[:severity_breakdown], "low")}
            </div>
          </div>
          <div class="stat bg-warning/10 rounded-lg p-3">
            <div class="stat-title text-xs">Medium</div>
            <div class="stat-value text-xl text-warning">
              {safe(@stats[:severity_breakdown], "medium")}
            </div>
          </div>
          <div class="stat bg-error/10 rounded-lg p-3">
            <div class="stat-title text-xs">High</div>
            <div class="stat-value text-xl text-error">
              {safe(@stats[:severity_breakdown], "high")}
            </div>
          </div>
        </div>

        <%!-- Recent Alerts --%>
        <div class="overflow-x-auto">
          <table class="table table-xs">
            <thead>
              <tr>
                <th>Alert</th>
                <th>Severity</th>
                <th>When</th>
              </tr>
            </thead>
            <tbody>
              <tr :if={Enum.empty?(safe(@stats, :recent_alerts, []))}>
                <td colspan="3" class="text-center text-base-content/50 py-8">
                  Recent alerts will appear here...
                </td>
              </tr>

              <tr
                :for={alert <- safe(@stats, :recent_alerts, [])}
                phx-click="navigate_alert"
                phx-value-id={alert.id}
                class="cursor-pointer hover:bg-base-200"
              >
                <td>{alert.alert_title}</td>
                <td>{alert.alert_severity}</td>
                <td>{alert.inserted_at}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>
    """
  end

  defp safe(_from, _key, default \\ 0)
  defp safe(nil, _key, default), do: default
  defp safe(from, key, default), do: Map.get(from, key, default)
end
