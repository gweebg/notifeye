defmodule Notifeye.Accounts.UserNotificationPreferences do
  @moduledoc """
  User notification preferences schema that manages email and Rocket.Chat notification settings.

  This embedded schema allows users to configure their preferred notification providers
  and their respective settings.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Notifeye.Notifications.ProviderSettings

  @primary_key false
  embedded_schema do
    embeds_one :email, ProviderSettings.Email, on_replace: :update
    embeds_one :rocket_chat, ProviderSettings.RocketChat, on_replace: :update
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [])
    |> cast_embed(:email, with: &ProviderSettings.Email.changeset/2)
    |> cast_embed(:rocket_chat, with: &ProviderSettings.RocketChat.changeset/2)
  end
end
