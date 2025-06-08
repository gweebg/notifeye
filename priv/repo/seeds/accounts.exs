defmodule Notifeye.Repo.Seeds.Accounts do
  alias Notifeye.Accounts

  @users ~w(guilherme@notifeye.com logz@eurotux.com)

  def run do
    case accounts?() do
      false -> generate_users(@users)
      _  -> Mix.shell().error("Database already has accounts, aborting seeding process.")
    end
  end

  defp accounts? do
    case Notifeye.Repo.all(Accounts.User) do
      [] -> false
      _  -> true
    end
  end

  defp generate_users(users) do
    for email <- users do
      # Register the user
      {:ok, user} = Accounts.register_user(%{"email" => email})

      # Verify the user & login
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, user, _expired_tokens} = Accounts.login_user_by_magic_link(token)

      # Generate a user API key
      token = Accounts.create_user_api_token(user)
      Mix.shell().info("User #{user.email} created with API token: #{token}")
    end
  end

  defp extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

end

Notifeye.Repo.Seeds.Accounts.run()
