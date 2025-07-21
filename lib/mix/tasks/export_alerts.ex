defmodule Mix.Tasks.Alerts.Export do
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

  alias Notifeye.Repo
  alias Notifeye.Monitoring.Alert

  def run(args) do
    Mix.Task.run("app.start")

    output_path = parse_args(args)
    alerts = Repo.all(Alert) |> Jason.encode!(pretty: true)

    File.write!(output_path, alerts)

    Mix.shell().info("Alerts exported to #{output_path}")
  end

  defp parse_args([path]), do: path
  defp parse_args(_), do: "alerts.json"
end
