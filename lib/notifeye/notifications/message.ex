defmodule Notifeye.Notifications.Message do
  @moduledoc """
  This module represents a notification message to be sent via a
  notification provider.
  """

  alias Notifeye.Accounts.User
  alias Notifeye.Notifications.Providers.{Email, RocketChat}

  @default_providers [Email, RocketChat]

  @enforce_keys ~w(type data to)a
  defstruct [
    :type,
    :data,
    :to,
    providers: @default_providers,
    results: %{},
    metadata: %{rule: false}
  ]

  @type t :: %__MODULE__{
          type: message_type(),
          data: map() | struct(),
          to: User.t(),
          providers: [module()],
          results: map() | struct(),
          metadata: map()
        }

  @type message_type ::
          :description_created
          | :assignment_created
          | :lead_notification
          | :group_notification
end
