defmodule Mix.Tasks.ExportAlerts do
  @moduledoc """
  Exports all alerts to a JSON file, excluding the user that added it and eventual
  table metadata.

  ## Usage

      mix export users path/to/alerts.json

  If no path is given, defaults to `alerts.json`.
  """

  @shortdoc "Export alerts from the database to a file as JSON"

  use Mix.Task

  def run(args) do
    Mix.Task.run("app.start")

    alias Notifeye.Repo
    alias Notifeye.Monitoring.Alert

    output_path = get_path(args)
    alerts = Repo.all(Alert) |> Jason.encode!(pretty: true)

    File.write!(output_path, alerts)

    Mix.shell().info("Alerts exported to #{output_path}")
  end

  defp get_path(args) do
    case args do
      [path] -> path
      _ -> "alerts.json"
    end
  end
end
