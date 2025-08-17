defmodule NotifeyeWeb.NavigationConfig do
  @moduledoc """
  Configuration for navigation sections and routes.
  This module defines the navigation structure and determines which
  sections should be expanded based on the current route.
  """

  @doc """
  Returns the navigation structure with sections and their routes.
  """
  def navigation_sections do
    %{
      "notifications" => %{
        title: "Notifications",
        icon: "hero-bell",
        routes: [
          %{
            name: "Dashboard",
            path: "/admin/notifications",
            icon: "hero-arrow-trending-up"
          },
          %{
            name: "Groups",
            path: "/admin/descriptions/groups",
            icon: "hero-rectangle-group"
          }
        ]
      },
      "admin" => %{
        title: "Alerts",
        icon: "hero-lock-closed",
        routes: [
          %{
            name: "Descriptions",
            path: "/admin/descriptions",
            icon: "hero-document-text"
          },
          %{
            name: "Alert Assignments",
            path: "/admin/users",
            icon: "hero-shield-check"
          }
        ]
      }
    }
  end

  @doc """
  Determines if a section should be expanded based on the current path.
  """
  def section_expanded?(section_key, current_path) do
    section = navigation_sections()[section_key]

    if section do
      Enum.any?(section.routes, fn route ->
        String.starts_with?(current_path, route.path)
      end)
    else
      false
    end
  end

  @doc """
  Determines if a specific route is currently active.
  """
  def route_active?(route_path, current_path) do
    String.starts_with?(current_path, route_path)
  end

  @doc """
  Gets the current section key based on the path.
  """
  def current_section(current_path) do
    navigation_sections()
    |> Enum.find_value(fn {key, _section} ->
      expanded = section_expanded?(key, current_path)
      if expanded, do: key, else: nil
    end)
  end
end
