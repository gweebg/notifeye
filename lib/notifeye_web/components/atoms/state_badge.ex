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
  attr :text_func, :any, default: &__MODULE__.state_display_name/1

  def state_badge(assigns) do
    assigns = assign(assigns, :color_class, assigns.color_func.(assigns.state))
    assigns = assign(assigns, :text_func, assigns.text_func)

    ~H"""
    <div class={[@class, @color_class]}>
      {@text_func.(assigns.state)}
    </div>
    """
  end

  def default_state_color(:enabled), do: "badge-success"
  def default_state_color(:disabled), do: "badge-warning"
  def default_state_color(:grouponly), do: "badge-info"
  def default_state_color(_), do: "badge-error"

  def state_display_name(:enabled), do: "Enabled"
  def state_display_name(:disabled), do: "Disabled"
  def state_display_name(:grouponly), do: "Group Only"
  def state_display_name(state), do: String.capitalize(to_string(state))
end
