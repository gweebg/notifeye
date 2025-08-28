defmodule Notifeye.Repo.Seeds.Accounts do
  alias Notifeye.{Accounts, Repo}
  alias Notifeye.Accounts.User

  @domain "notifeye.com"
  @users ~w(nier yonah kaine emil devola popola nines atwo twob adam)

  def run do
    if accounts_exist?() do
      Mix.shell().error("Database already has accounts, aborting seeding process.")
    else
      seed()
    end
  end

  defp seed do
    Accounts.create_admin_user(%{email: "admin@#{@domain}"})
    create_users()
  end

  defp create_users do
    @users
    |> Enum.map(fn name -> "#{name}@#{@domain}" end)
    |> Enum.map(&Accounts.register_user(%{email: &1}))
    |> Enum.split_with(&match?({:ok, _}, &1))
    |> case do
      {oks, []} -> Mix.shell().info("Generated #{length(oks)} users and an administrator.")
      {_, errors} -> Mix.shell().error("Failed to generate #{length(errors)} accounts: #{inspect(errors)}")
    end
  end

  defp accounts_exist? do
    Repo.exists?(User)
  end
end

Notifeye.Repo.Seeds.Accounts.run()
