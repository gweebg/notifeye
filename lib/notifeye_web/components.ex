defmodule NotifeyeWeb.Components do
  @moduledoc """
  Imports all reusable components for the Notifeye web application.

  Use this module to import all components at once:

      import NotifeyeWeb.Components

  Or import specific component modules individually:

      import NotifeyeWeb.Components.StateBadge
      import NotifeyeWeb.Components.VerifiedBadge
  """

  defmacro __using__(_) do
    quote do
      import NotifeyeWeb.Components.Atoms.StateBadge
      import NotifeyeWeb.Components.Atoms.VerifiedBadge
      import NotifeyeWeb.Components.Atoms.NotificationGroupDisplay
      import NotifeyeWeb.Components.Atoms.UpdatedByDisplay

      import NotifeyeWeb.Components.Cards.StatusCard

      import NotifeyeWeb.Components.Placeholders.RulesGuide
      import NotifeyeWeb.Components.Placeholders.RulesEmpty

      import NotifeyeWeb.Components.Assignments.StatusSection
      import NotifeyeWeb.Components.Assignments.AdminActions
      import NotifeyeWeb.Components.Assignments.AcknowledgmentForm
      import NotifeyeWeb.Components.Assignments.AlertDetails

      import NotifeyeWeb.Components.Dashboard.AlertsStats
    end
  end

  # Re-export component functions for direct import
  defdelegate state_badge(assigns), to: NotifeyeWeb.Components.Atoms.StateBadge
  defdelegate verified_badge(assigns), to: NotifeyeWeb.Components.Atoms.VerifiedBadge

  defdelegate notification_group_display(assigns),
    to: NotifeyeWeb.Components.Atoms.NotificationGroupDisplay

  defdelegate updated_by_display(assigns), to: NotifeyeWeb.Components.Atoms.UpdatedByDisplay

  defdelegate status_card(assigns), to: NotifeyeWeb.Components.Cards.StatusCard
end
