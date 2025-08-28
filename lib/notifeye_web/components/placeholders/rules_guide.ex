defmodule NotifeyeWeb.Components.Placeholders.RulesGuide do
  @moduledoc """
  Empty state component displayed when no alert description is selected.
  """

  use Phoenix.Component
  import NotifeyeWeb.CoreComponents

  @doc """
  Renders an empty state with instructions for selecting an alert description.
  """
  def rules_guide(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-16 px-6 text-center">
      <div class="mb-2">
        <.icon name="hero-funnel" class="w-24 h-24 mx-auto" />
      </div>

      <div class="max-w-md space-y-2">
        <h3 class="text-xl font-semibold text-base-content">
          Select an Alert Description
        </h3>

        <p class="text-base-content/70 leading-relaxed">
          Choose an alert description from the dropdown above to view and manage its rules.
          Rules define how notifications are sent when alerts match specific criteria.
        </p>
      </div>
    </div>
    """
  end
end
