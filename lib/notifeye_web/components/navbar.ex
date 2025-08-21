defmodule NotifeyeWeb.Components.Navbar do
  @moduledoc false

  use NotifeyeWeb, :live_component

  alias NotifeyeWeb.NavigationConfig

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <nav class="flex flex-col h-full bg-base-100">
      <%!-- App Header --%>
      <div class="p-6">
        <div class="flex items-center gap-3">
          <div class="avatar">
            <div class="w-8 h-8 rounded-lg bg-primary flex items-center justify-center"></div>
          </div>
          <h1 class="text-lg font-semibold">Notifeye</h1>
        </div>
      </div>

      <%!-- Navigation Sections --%>
      <div class="flex-1 overflow-y-auto p-2">
        <%= for {key, section} <- NavigationConfig.navigation_sections() do %>
          <%= case section.type do %>
            <% :single -> %>
              <%!-- Single Item (no collapsible) --%>
              <div class="mb-3 mx-2">
                <.link
                  navigate={section.path}
                  class={[
                    "flex items-center gap-2 rounded-lg px-2 py-3 w-full font-semibold",
                    if(NavigationConfig.route_active?(section.path, @current_path),
                      do: "bg-primary text-primary-content",
                      else: "hover:bg-base-200"
                    )
                  ]}
                >
                  <.icon name={"hero-" <> section.icon} class="size-5" />
                  {section.label}
                </.link>
              </div>
            <% :multiple -> %>
              <%!-- Collapsible Section --%>
              <div class="collapse collapse-arrow mb-2">
                <input
                  type="checkbox"
                  checked={NavigationConfig.section_expanded?(key, @current_path)}
                />
                <div class="collapse-title font-semibold flex items-center gap-2">
                  <.icon name={"hero-" <> section.icon} class="size-5" />
                  <p>{section.label}</p>
                </div>
                <div class="collapse-content text-md">
                  <ul class="menu p-0 gap-2 w-full">
                    <%= for route <- section.routes do %>
                      <li class="w-full">
                        <.link
                          navigate={route.path}
                          class={[
                            "flex items-center gap-2 rounded-lg px-3 py-2",
                            if(NavigationConfig.route_active?(route.path, @current_path),
                              do: "bg-primary text-primary-content",
                              else: "hover:bg-base-200"
                            )
                          ]}
                        >
                          <.icon name={"hero-" <> route.icon} class="w-4 h-4" />
                          {route.name}
                        </.link>
                      </li>
                    <% end %>
                  </ul>
                </div>
              </div>
          <% end %>
        <% end %>
      </div>
      
    <!-- Bottom Section: Theme + Account -->
      <div class="p-4 border-t border-base-300 space-y-3">
        <!-- Theme Switcher -->
        <div class="flex justify-center">
          <Layouts.theme_toggle />
        </div>
        
    <!-- Account Section -->
        <div class="flex items-center gap-3 p-2 rounded-lg hover:bg-base-200 cursor-pointer">
          <div class="avatar placeholder">
            <div class="bg-neutral text-neutral-content rounded-full w-8">
              <span class="text-xs">
                <%= if @current_scope && @current_scope.user do %>
                  {String.first(@current_scope.user.email) |> String.upcase()}
                <% else %>
                  ?
                <% end %>
              </span>
            </div>
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-sm font-medium truncate">
              <%= if @current_scope && @current_scope.user do %>
                {@current_scope.user.email}
              <% else %>
                Guest
              <% end %>
            </div>
          </div>
          <.icon name="hero-chevron-right" class="w-4 h-4 opacity-50" />
        </div>
      </div>
    </nav>
    """
  end
end
