defmodule NotifeyeWeb.Components.Placeholders.RulesEmpty do
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

  def rules_empty(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-16 px-6 text-center">
      <div class="mb-6">
        <.icon name="hero-face-frown" class="w-24 h-24 mx-auto" />
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
          <.link
            navigate={"/descriptions/#{@description_id}/rules/new"}
            class="btn btn-primary gap-2 mb-2"
          >
            <.icon name="hero-plus" class="w-4 h-4" /> Create Rule
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
