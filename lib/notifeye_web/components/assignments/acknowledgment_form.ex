defmodule NotifeyeWeb.Components.Assignments.AcknowledgmentForm do
  @moduledoc """
  Component for user acknowledgment form.

  Shows the phrase-based acknowledgment form for users who own the assignment.
  """

  use NotifeyeWeb, :live_component

  def render(assigns) do
    ~H"""
    <section>
      <div :if={@meta.show_user_acknowledgment} class="card bg-base-100 shadow-sm">
        <form phx-submit="acknowledge" phx-change="validate" class="card-body flex flex-col gap-4">
          <h3 class="card-title">Your Statement</h3>

          <p class="text-sm text-base-content/70">
            To acknowledge this alert that was assigned to you, please
            type out the phrase below. By acknowledging, you confirm that
            you have reviewed and understood this alert assignment.
          </p>

          <div class="card bg-base-200 flex flex-row gap-2 items-center p-2">
            <.icon name="hero-chevron-right" class="size-4" />
            <p class="text-sm">
              {@required_phrase}
            </p>
          </div>

          <input
            id="acknowledgment_phrase"
            name="acknowledgment_phrase"
            value={@acknowledgment_phrase}
            phx-hook="NoPaste"
            phx-debounce="250"
            class={[
              "input input-bordered w-full resize-none",
              if(@acknowledgment_phrase != "" and @acknowledgment_phrase != @required_phrase,
                do: "input-error",
                else:
                  if(@acknowledgment_phrase == @required_phrase,
                    do: "input-success",
                    else: ""
                  )
              )
            ]}
            placeholder="Type the exact phrase here..."
            required
            autocomplete="off"
            spellcheck="false"
          />

          <%= if @acknowledgment_phrase != "" and @acknowledgment_phrase != @required_phrase do %>
            <div class="label">
              <span class="label-text-alt text-error">
                Phrase doesn't match. Please type exactly as shown above.
              </span>
            </div>
          <% end %>

          <div class="card-actions justify-end items-center">
            <button
              type="submit"
              phx-disable-with="Saving..."
              disabled={@acknowledgment_phrase != @required_phrase}
              class={[
                "btn mt-2",
                if(@acknowledgment_phrase != @required_phrase,
                  do: "btn-disabled",
                  else: "btn-primary"
                )
              ]}
            >
              Acknowledge
            </button>
          </div>
        </form>
      </div>
    </section>
    """
  end
end
