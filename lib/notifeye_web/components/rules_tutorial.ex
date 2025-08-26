defmodule NotifeyeWeb.Components.RulesTutorial do
  @moduledoc """
  Tutorial component displayed when a description is selected but has no rules.
  """

  use Phoenix.Component
  import NotifeyeWeb.CoreComponents

  @doc """
  Renders a tutorial state with instructions for creating the first rule.

  ## Attributes

  * `description_id` - The ID of the selected alert description
  """
  attr :description_id, :integer, required: true

  def rules_tutorial(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-16 px-6 text-center">
      <div class="mb-6">
        <.icon name="hero-plus-circle" class="w-24 h-24 text-base-300 mx-auto" />
      </div>

      <div class="max-w-lg space-y-4">
        <h3 class="text-xl font-semibold text-base-content">
          No Rules Found
        </h3>

        <p class="text-base-content/70 leading-relaxed">
          This alert description doesn't have any rules yet. Create your first rule to
          define how notifications should be handled when alerts match specific conditions.
        </p>

        <div class="mt-6">
          <button class="btn btn-primary gap-2" disabled title="Coming soon">
            <.icon name="hero-plus" class="w-4 h-4" /> Create First Rule
          </button>
        </div>

        <div class="mt-8 p-4 bg-base-200 rounded-lg text-left">
          <h4 class="font-medium text-sm mb-3 flex items-center gap-2">
            <.icon name="hero-information-circle" class="w-4 h-4" /> About Rules
          </h4>
          <div class="text-sm text-base-content/70 space-y-2">
            <p>Rules allow you to:</p>
            <ul class="list-disc list-inside space-y-1 ml-2">
              <li>Filter alerts based on specific criteria</li>
              <li>Define notification methods (email, Slack, etc.)</li>
              <li>Control when and how alerts trigger notifications</li>
            </ul>
            <p class="mt-3 text-xs">
              <strong>Note:</strong> Only one rule can be active per alert description at a time.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
