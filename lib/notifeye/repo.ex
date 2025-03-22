defmodule Notifeye.Repo do
  use Ecto.Repo,
    otp_app: :notifeye,
    adapter: Ecto.Adapters.Postgres
end
