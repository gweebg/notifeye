defmodule NotifeyeWeb.NavigationConfig do
  @moduledoc """
  Configuration for navigation sections and routes.
  This module defines the navigation structure and determines which
  sections should be expanded based on the current route.
  """

  @routes [
    {
      :dashboard,
      %{
        type: :single,
        label: "Admin Dashboard",
        icon: "rectangle-group",
        path: "/"
      }
    },
    {
      :alerts,
      %{
        type: :multiple,
        label: "Alerts",
        icon: "shield-exclamation",
        routes: [
          %{id: :alerts, name: "Alerts", path: "/alerts", icon: "server"},
          %{
            id: :descriptions,
            name: "Descriptions",
            path: "/descriptions",
            icon: "document-text"
          },
          %{id: :assignments, name: "Assignments", path: "/assignments", icon: "shield-check"}
        ]
      }
    },
    {
      :notifications,
      %{
        type: :multiple,
        label: "Notifications",
        icon: "bell",
        routes: [
          %{name: "Dashboard", path: "/notifications", icon: "arrow-trending-up"},
          %{name: "Groups", path: "/notifications/groups", icon: "server"}
        ]
      }
    },
    {
      :admin,
      %{
        type: :multiple,
        label: "Administration",
        icon: "lock-closed",
        routes: [
          %{name: "Users", path: "/admin/users", icon: "users"}
        ]
      }
    }
  ]

  @doc """
  Returns the navigation structure with sections and their routes.
  """
  def navigation_sections, do: @routes

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
  Uses exact matching or path-specific logic to avoid conflicts.

  todo: remove hardcoded stuff
  """
  def route_active?(route_path, current_path) do
    cond do
      # exact match
      route_path == current_path ->
        true

      # For root paths, only match exact
      route_path in ["/", "/notifications", "/alerts", "/admin"] ->
        route_path == current_path

      # For sub-paths, use starts_with but ensure it's not a false positive
      true ->
        String.starts_with?(current_path, route_path) and
          (String.length(current_path) == String.length(route_path) or
             String.at(current_path, String.length(route_path)) == "/")
    end
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
