defmodule NotifeyeWeb.Components.Atoms.UpdatedByDisplay do
  @moduledoc """
  Updated by display component with user information
  """
  use Phoenix.Component

  @doc """
  Renders user information with avatar and name.

  ## Attributes

  * `user` - The user struct (default: nil)
  * `class` - Base CSS classes for the container (default: "flex items-center gap-2")
  * `show_avatar` - Whether to display the user avatar (default: true)
  * `avatar_class` - CSS classes for the avatar (default: "bg-neutral text-neutral-content rounded-full w-6 h-6 text-xs")
  * `no_user_text` - Text to show when no user is assigned (default: "No user")
  * `no_user_class` - CSS classes for the "no user" state (default: "text-sm text-base-content/50")
  """
  attr :user, :map, default: nil
  attr :class, :string, default: "text-sm text-gray-500"
  attr :no_user_text, :string, default: "No user"
  attr :no_user_class, :string, default: "text-base-content/50 text-sm"
  attr :show_avatar, :boolean, default: true
  attr :avatar_class, :string, default: "h-10 w-10 rounded-full"

  def updated_by_display(assigns) do
    ~H"""
    <%= if @user do %>
      <div class={["tooltip ml-5", @class]}>
        <div class="tooltip-content">
          {@user.email}
        </div>
        <div :if={@show_avatar} class="avatar">
          <div class={@avatar_class}>
            <img src="https://img.daisyui.com/images/profile/demo/yellingcat@192.webp" />
          </div>
        </div>
        <span :if={not @show_avatar} class={@class}>
          {@user.email}
        </span>
      </div>
    <% else %>
      <span class={["ml-4", @no_user_class]}>
        {@no_user_text}
      </span>
    <% end %>
    """
  end
end
