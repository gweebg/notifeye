defmodule NotifeyeWeb.Components.Cards.AlertCard do
  use NotifeyeWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="card w-max bg-base-100 shadow-sm">
      <div class="card-body">
        {severity_badge(assigns)}
        <h2 class="text-3xl font-bold">{@alert.alert_title}</h2>
        <p class="text-gray-600 line-clamp-3">{@alert.alert_description}</p>
        <div class="mt-6">
          <button class="btn btn-primary btn-block">Handle</button>
        </div>
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
