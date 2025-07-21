defmodule Mix.Tasks.Alerts.Import do
  @moduledoc """
  Imports alerts from a JSON file into the database.

  ## Parameters
    - `path` - A valid path to a JSON file containing exported alerts. Required.

  ## Usage
      mix alerts.import path/to/file.json
  """

  @shortdoc "Import alerts into the database from a JSON file"

  use Mix.Task

  alias Notifeye.Accounts
  alias Notifeye.Monitoring

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    args
    |> parse_args()
    |> import_alerts_from_file()

    Mix.shell().info("Alerts imported successfully!")
  end

  defp parse_args([path]), do: path
  defp parse_args(_), do: Mix.raise("Usage: mix alerts.import path/to/file.json")

  defp import_alerts_from_file(path) do
    with {:ok, content} <- File.read(path),
         {:ok, alerts} <- Jason.decode(content) do
      admin = Accounts.get_admin_user!()
      scope = Accounts.Scope.for_user(admin)

      alerts
      |> Enum.each(&import_alert(scope, &1))
    else
      {:error, reason} ->
        Mix.raise("Failed to read or parse alerts file: #{inspect(reason)}")
    end
  end

  defp import_alert(scope, alert) do
    alert
    |> Map.drop(~w[id inserted_at updated_at user_id]a)
    |> then(&Monitoring.create_alert(scope, &1))
    |> case do
      {:ok, _alert} -> :ok
      {:error, changeset} -> Mix.shell().error("Error importing alert: #{inspect(changeset)}")
    end
  end
end
