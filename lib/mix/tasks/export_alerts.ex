defmodule Mix.Tasks.ExportAlerts do
  @moduledoc """
  Exports all alerts to a JSON file, excluding the user that added it and eventual
  table metadata.

  ## Parameters
  - `path` - A valid path to a file where the alerts will be exported. If not
    provided, defaults to `alerts.json`.

  ## Usage
      mix export_alerts [path]

  ## Example
      mix export_alerts all_alerts.json
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
