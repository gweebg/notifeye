defmodule NotifeyeWeb.Components.Modals.NotificationGroupShow do
  @moduledoc """
  Reusable notification group show modal component.

  Displays detailed information about a notification group including:
  - Basic information (name, description)
  - Member list
  - Associated alert descriptions
  - Actions (edit, delete if enabled)
  """

  use Phoenix.Component
  import NotifeyeWeb.CoreComponents

  # Import route helpers
  use NotifeyeWeb, :html

  @doc """
  Renders a show modal for a notification group.

  ## Attributes

  * `group` - The notification group struct to display (required)
  * `alert_descriptions` - List of alert descriptions using this group (default: [])
  * `show` - Whether to show the modal (default: false)
  * `show_actions` - Whether to show action buttons (default: true)
  * `on_close` - Event to emit when closing the modal (default: "close_show_modal")
  * `on_edit` - Event to emit when editing (default: "edit_group")
  * `on_delete` - Event to emit when deleting (default: "confirm_delete")
  """

  attr :group, :map, required: true
  attr :alert_descriptions, :list, default: []
  attr :show, :boolean, default: false
  attr :show_actions, :boolean, default: true
  attr :on_close, :string, default: "close_show_modal"
  attr :on_edit, :string, default: "edit_group"
  attr :on_delete, :string, default: "confirm_delete"

  def notification_group_show(assigns) do
    ~H"""
    <dialog :if={@show} open class="modal overflow-hidden" id="notification_group_show_modal">
      <div class="modal-box w-full max-w-2xl">
        <h3 class="flex flex-row items-center font-medium text-xl text-primary mb-4 gap-2">
          <.icon name="hero-eye" class="w-6 h-6" /> Notification Group Details
        </h3>

        <div class="space-y-6">
          <%!-- Basic Information --%>
          <div class="space-y-4">
            <div>
              <label class="label pb-1">
                <span class="label-text font-semibold">Name</span>
              </label>
              <div class="flex items-center space-x-2">
                <.icon name="hero-tag" class="w-4 h-4 text-gray-500" />
                <span class="text-sm font-medium">{@group.name}</span>
              </div>
            </div>

            <div>
              <label class="label pb-1">
                <span class="label-text font-semibold">Description</span>
              </label>
              <div class="flex items-start space-x-2">
                <.icon name="hero-document-text" class="w-4 h-4 text-gray-500 mt-0.5" />
                <span class="text-sm">
                  {@group.description || "No description provided"}
                </span>
              </div>
            </div>

            <div>
              <label class="label pb-1">
                <span class="label-text font-semibold">Created</span>
              </label>
              <div class="flex items-center space-x-2">
                <.icon name="hero-calendar" class="w-4 h-4 text-gray-500" />
                <span class="text-sm">
                  {Calendar.strftime(@group.inserted_at, "%B %d, %Y at %H:%M UTC")}
                </span>
              </div>
            </div>

            <div>
              <label class="label pb-1">
                <span class="label-text font-semibold">Last Updated</span>
              </label>
              <div class="flex items-center space-x-2">
                <.icon name="hero-clock" class="w-4 h-4 text-gray-500" />
                <span class="text-sm">
                  {Calendar.strftime(@group.updated_at, "%B %d, %Y at %H:%M UTC")}
                </span>
              </div>
            </div>
          </div>

          <%!-- Members Section --%>
          <div>
            <label class="label pb-2">
              <span class="label-text font-semibold flex items-center gap-2">
                <.icon name="hero-users" class="w-4 h-4" /> Members ({length(@group.users)})
              </span>
            </label>

            <div :if={length(@group.users) > 0} class="space-y-2">
              <div class="max-h-32 overflow-y-auto border border-base-300 rounded-lg">
                <div
                  :for={user <- @group.users}
                  class="flex items-center justify-between p-3 hover:bg-base-200 border-b border-base-200 last:border-b-0"
                >
                  <div class="flex flex-col">
                    <span class="text-sm font-medium">{user.username || user.email}</span>
                    <span :if={user.username} class="text-xs text-base-content/50">{user.email}</span>
                  </div>
                  <span class="badge badge-soft badge-neutral badge-sm">Member</span>
                </div>
              </div>
            </div>

            <div
              :if={length(@group.users) == 0}
              class="text-center py-6 border border-base-300 rounded-lg bg-base-50"
            >
              <.icon name="hero-user-plus" class="w-8 h-8 text-gray-300 mx-auto mb-2" />
              <p class="text-gray-500 text-sm">No members yet</p>
              <p class="text-gray-400 text-xs">
                Add users to this notification group to start receiving alerts.
              </p>
            </div>
          </div>

          <%!-- Alert Descriptions Section --%>
          <div>
            <label class="label pb-2">
              <span class="label-text font-semibold flex items-center gap-2">
                <.icon name="hero-bell" class="w-4 h-4" />
                Alert Descriptions ({length(@alert_descriptions)})
              </span>
            </label>

            <div :if={length(@alert_descriptions) > 0} class="space-y-2">
              <div class="max-h-40 overflow-y-auto border border-base-300 rounded-lg">
                <div
                  :for={description <- @alert_descriptions}
                  class="flex items-center justify-between p-3 hover:bg-base-200 border-b border-base-200 last:border-b-0"
                >
                  <div class="flex flex-col">
                    <span class="text-sm font-medium font-mono">ID: {description.id}</span>
                    <div class="flex items-center gap-2 mt-1">
                      <span class={[
                        "badge badge-sm",
                        case description.state do
                          :enabled -> "badge-success"
                          :disabled -> "badge-error"
                          :grouponly -> "badge-warning"
                        end
                      ]}>
                        {String.capitalize(to_string(description.state))}
                      </span>
                      <span class={[
                        "badge badge-sm",
                        if(description.verified, do: "badge-info", else: "badge-neutral")
                      ]}>
                        {if description.verified, do: "Verified", else: "Unverified"}
                      </span>
                    </div>
                  </div>
                  <.link
                    navigate={~p"/descriptions/#{description.id}"}
                    class="btn btn-ghost btn-sm"
                    data-tip="View Description"
                  >
                    <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4" />
                  </.link>
                </div>
              </div>
            </div>

            <div
              :if={length(@alert_descriptions) == 0}
              class="text-center py-6 border border-base-300 rounded-lg bg-base-50"
            >
              <.icon name="hero-bell-slash" class="w-8 h-8 text-gray-300 mx-auto mb-2" />
              <p class="text-gray-500 text-sm">No alert descriptions configured</p>
              <p class="text-gray-400 text-xs">
                This notification group is not being used by any alert descriptions yet.
              </p>
            </div>
          </div>
        </div>

        <%!-- Modal Actions --%>
        <div class="modal-action">
          <button type="button" class="btn btn-outline" phx-click={@on_close}>
            Close
          </button>

          <div :if={@show_actions} class="flex gap-2">
            <button
              type="button"
              class="btn btn-primary btn-outline"
              phx-click={@on_edit}
              phx-value-id={@group.id}
            >
              <.icon name="hero-pencil" class="w-4 h-4" /> Edit
            </button>
          </div>
        </div>
      </div>
    </dialog>
    """
  end
end
