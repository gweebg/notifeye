defmodule Notifeye.Notifications.Providers do
  @moduledoc "Central place where all notification providers are registered."

  alias Notifeye.Notifications.Providers

  @providers [
    Providers.Email,
    Providers.RocketChat
  ]

  def all, do: @providers

  def names do
    Enum.map(@providers, & &1.provider_name())
  end
end
