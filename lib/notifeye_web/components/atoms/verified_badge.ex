defmodule NotifeyeWeb.Components.Atoms.VerifiedBadge do
  @moduledoc """
  Verified badge component for alert descriptions
  """
  use Phoenix.Component

  @doc """
  Renders a verified badge for an alert description.

  ## Attributes

  * `verified` - Boolean indicating verification status (required)
  * `class` - Base CSS classes for the badge (default: "badge")
  * `verified_color` - CSS class for verified state (default: "badge-success")
  * `unverified_color` - CSS class for unverified state (default: "badge-error")
  """
  attr :verified, :boolean, required: true
  attr :class, :string, default: "badge"
  attr :verified_color, :string, default: "badge-success"
  attr :unverified_color, :string, default: "badge-error"

  def verified_badge(assigns) do
    ~H"""
    <div class={[@class, if(@verified, do: @verified_color, else: @unverified_color)]}>
      {if @verified, do: "Verified", else: "Unverified"}
    </div>
    """
  end
end
