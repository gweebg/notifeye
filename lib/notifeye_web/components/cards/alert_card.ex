defmodule NotifeyeWeb.Components.Cards.AlertCard do
  @moduledoc """
  A component to display an alert card with details like title, description, severity, and tags.
  It includes a link to the alert details page and displays the creation date.
  """

  use NotifeyeWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="card w-full bg-base-100 shadow-sm cursor-pointer hover:bg-base-200 transition-colors duration-200">
      <div class="card-body">
        <.link navigate={~p"/alerts/#{@alert.id}"}>
          <div class="space-y-2">
            <div class="flex items-center justify-between">
              {severity_badge(assigns)}
              <span class="text-sm text-gray-500">
                {@alert.inserted_at |> Timex.format!("%Y-%m-%d %H:%M:%S", :strftime)}
              </span>
            </div>
            <h2 class="text-2xl font-bold">{@alert.alert_title}</h2>
            <p class="text-gray-600 line-clamp-3">{@alert.alert_description}</p>
            <section>
              <%= for tag <- @alert.alert_tags do %>
                <span class="badge badge-soft badge-primary badge-sm mr-1 mb-1">
                  {tag}
                </span>
              <% end %>
            </section>
          </div>
        </.link>
      </div>
    </div>
    """
  end

  defp severity_badge(assigns) do
    ~H"""
    <span class={"badge badge-s #{badge_class(@alert.alert_severity)}"}>
      {@alert.alert_severity}
    </span>
    """
  end

  defp badge_class("High"), do: "badge-error"
  defp badge_class("Medium"), do: "badge-warning"
  defp badge_class("Low"), do: "badge-success"
  defp badge_class(_), do: "badge-ghost"
end
