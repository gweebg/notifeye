defmodule Notifeye.Notifications.ProviderSettings.Email do
  @moduledoc """
  Email provider settings schema for notification configurations.

  This module defines the embedded schema for email notification settings,
  including email address validation and enabled/disabled state.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :enabled, :boolean, default: true
    field :email_address, :string, default: "example@example.com"
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:enabled, :email_address])
    |> validate_format(:email_address, ~r/^[^@,;\s]+@[^@,;\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:email_address, max: 160)
  end
end
