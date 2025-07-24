defmodule NotifeyeWeb.Components.Cards.StatusCard do
  @moduledoc false

  use Phoenix.Component

  # Generic card component
  attr :title, :string, required: true
  attr :title_class, :string, default: ""
  attr :description, :string, required: true
  slot :inner_block, required: false

  def status_card(assigns) do
    ~H"""
    <div class="card shadow-sm bg-base-100 flex-1">
      <div class="card-body p-4 text-center flex flex-col justify-between items-center gap-2">
        <div class="flex flex-col">
          <h4 class={["font-semibold text-sm", @title_class]}>
            {@title}
          </h4>
          <p class="text-xs opacity-70">{@description}</p>
        </div>
        <div class="flex justify-center">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end
end
