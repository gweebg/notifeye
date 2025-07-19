defmodule NotifeyeWeb.Components.Atoms.NotificationGroupDisplay do
  @moduledoc """
  Notification group display component
  """
  use Phoenix.Component

  @doc """
  Renders notification group information.

  ## Attributes

  * `notification_group` - The notification group struct (default: nil)
  * `class` - Base CSS classes for the display (default: "text-sm")
  * `no_group_text` - Text to show when no group is assigned (default: "No group")
  * `no_group_class` - Additional CSS classes for the "no group" state (default: "text-base-content/50")
  """
  attr :notification_group, :map, default: nil
  attr :class, :string, default: "text-sm"
  attr :no_group_text, :string, default: "No group"
  attr :no_group_class, :string, default: "text-base-content/50"

  def notification_group_display(assigns) do
    ~H"""
    <%= if @notification_group do %>
      <span class={@class}>
        {@notification_group.name}
      </span>
    <% else %>
      <span class={[@class, @no_group_class]}>
        {@no_group_text}
      </span>
    <% end %>
    """
  end
end
