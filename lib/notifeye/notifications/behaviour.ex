defmodule Notifeye.Notifications.Behaviour do
  @moduledoc """
  Behaviour for notification providers.

  Each notification provider must implement the `send_notification/2` function
  to handle sending notifications through their specific means.
  """

  alias Notifeye.Accounts.User
  alias Notifeye.AlertDescriptions.AlertDescription
  alias Notifeye.AlertAssignments.AlertAssignment
  alias Notifeye.Notifications.NotificationGroup

  @typedoc """
  Types of notifications we will be sending.
  """
  @type notification_context ::
          {:description_created, AlertDescription.t()}
          | {:assignment_created, AlertAssignment.t()}
          | {:lead_notification, AlertAssignment.t()}
          | {:group_notification, NotificationGroup.t(), AlertAssignment.t()}

  @doc """
  Sends a notification to a user about an event.

  ## Returns:
  * `{:ok, %{} = metadata}` on successful delivery
  * `{:error, reason}` on failure
  * `{:skip, reason}` if the notification should be skipped
  """
  @callback send_notification(User.t(), notification_context()) ::
              {:ok, map()} | {:error, term()} | {:skip, term()}

  @doc """
  Returns the name/identifier of the notification provider.
  """
  @callback provider_name() :: String.t()

  @doc """
  Validates if the user has the necessary configuration for this provider.
  """
  @callback can_notify?(User.t()) :: boolean()

  @doc """
  Lists the implemented message types for this provider.
  """
  @callback supported_contexts() :: [atom()]
end
