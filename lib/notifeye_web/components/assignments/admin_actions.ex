defmodule NotifeyeWeb.Components.Assignments.AdminActions do
  @moduledoc """
  Component for admin-specific actions like transferring assignments and force acknowledge.

  Only renders for admin users and shows appropriate actions based on assignment status.
  """

  use NotifeyeWeb, :live_component

  def render(assigns) do
    ~H"""
    <section>
      <div
        :if={@meta.show_transfer_form or @meta.show_force_acknowledge}
        class="card bg-base-100 shadow-sm"
      >
        <div class="card-body">
          <%!-- Transfer to another user --%>
          <div :if={@meta.show_transfer_form} class="space-y-2">
            <h4 class="text-lg font-medium">Transfer Assignment</h4>
            <p class="text-sm text-base-content/70">
              Reassign this alert to another user. The assignment will be marked
              as 'open' for the new user.
            </p>

            <form
              phx-submit="transfer_assignment"
              phx-change="validate_transfer"
              class="flex flex-row gap-2"
            >
              <div class="form-control flex flex-1">
                <select name="transfer_user_id" class="select select-bordered w-full" required>
                  <option value="">Choose a user...</option>
                  <%= for user <- @available_users do %>
                    <option value={user.id} selected={@transfer_user_id == to_string(user.id)}>
                      {user.username || user.email} {if user.username, do: "(#{user.email})", else: ""}
                    </option>
                  <% end %>
                </select>
              </div>

              <div>
                <button
                  type="submit"
                  class="btn btn-primary"
                  disabled={is_nil(@transfer_user_id) || @transfer_user_id == ""}
                  phx-disable-with="Transferring..."
                >
                  Transfer Assignment
                </button>
              </div>
            </form>
          </div>

          <div :if={@meta.show_transfer_form and @meta.show_force_acknowledge} class="divider"></div>

          <%!-- Force acknowledge --%>
          <div :if={@meta.show_force_acknowledge} class="space-y-2">
            <h4 class="text-lg font-medium">Force Acknowledge</h4>
            <p class="text-sm text-base-content/70">
              Acknowledge this assignment on behalf of the assigned user without
              requiring the confirmation phrase. <br />
              {if @assignment.status ==
                    :expired,
                  do: "This will not restore points since the assignment has expired.",
                  else: "Points may be restored based on eligibility rules."}
            </p>

            <div class="flex justify-end">
              <button
                type="button"
                phx-click="force_acknowledge"
                class="btn btn-warning btn-soft"
                phx-disable-with="Working..."
              >
                <.icon name="hero-exclamation-triangle" class="size-5" /> Force Acknowledge
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end
end
