defmodule NotifeyeWeb.Components.Atoms.StateBadge do
  @moduledoc """
  State badge component for alert descriptions
  """
  use Phoenix.Component

  @doc """
  Renders a state badge for an alert description.

  ## Attributes

  * `state`: state of the `%AlertDescription{}` (required)
  * `class`: optional attribute for specifying a custom class for the component (default: "badge")
  * `color_func`: a function that, by receiving `state` as the argument, returns
    the corresponding color CSS class (default: `default_state_color/1`)
  """
  attr :state, :atom, required: true
  attr :class, :string, default: "badge"
  attr :color_func, :any, default: &__MODULE__.default_state_color/1

  def state_badge(assigns) do
    assigns = assign(assigns, :color_class, assigns.color_func.(assigns.state))

    ~H"""
    <div class={[@class, @color_class]}>
      {state_display_name(@state)}
    </div>
    """
  end

  def default_state_color(:enabled), do: "badge-success"
  def default_state_color(:disabled), do: "badge-warning"
  def default_state_color(:grouponly), do: "badge-info"
  def default_state_color(_), do: "badge-error"

  defp state_display_name(:enabled), do: "Enabled"
  defp state_display_name(:disabled), do: "Disabled"
  defp state_display_name(:grouponly), do: "Group Only"
  defp state_display_name(state), do: String.capitalize(to_string(state))
end
