defmodule Notifeye.Notifications.ProviderSettings.RocketChat do
  @moduledoc """
  Embedded schema for RocketChat notification provider settings.

  This module defines the configuration fields and validation rules
  for RocketChat notifications, including enabled status and username.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :enabled, :boolean, default: true
    field :username, :string, default: ""
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:enabled, :email_address])
    |> validate_length(:username, max: 128)
  end
end
