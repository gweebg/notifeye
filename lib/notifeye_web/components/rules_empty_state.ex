defmodule NotifeyeWeb.Components.RulesEmptyState do
  @moduledoc """
  Empty state component displayed when no alert description is selected.
  """

  use Phoenix.Component
  import NotifeyeWeb.CoreComponents

  @doc """
  Renders an empty state with instructions for selecting an alert description.
  """
  def rules_empty_state(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-16 px-6 text-center">
      <div class="mb-6">
        <.icon name="hero-funnel" class="w-24 h-24 text-base-300 mx-auto" />
      </div>

      <div class="max-w-md space-y-4">
        <h3 class="text-xl font-semibold text-base-content">
          Select an Alert Description
        </h3>

        <p class="text-base-content/70 leading-relaxed">
          Choose an alert description from the dropdown above to view and manage its rules.
          Rules define how notifications are sent when alerts match specific criteria.
        </p>

        <div class="mt-6 p-4 bg-base-200 rounded-lg text-left">
          <h4 class="font-medium text-sm mb-2 flex items-center gap-2">
            <.icon name="hero-light-bulb" class="w-4 h-4" /> Quick Guide
          </h4>
          <ul class="text-sm text-base-content/70 space-y-1">
            <li>• Select a description to see its rules</li>
            <li>• Create rules to automate notifications</li>
            <li>• Only one rule can be active per description</li>
          </ul>
        </div>
      </div>
    </div>
    """
  end
end
