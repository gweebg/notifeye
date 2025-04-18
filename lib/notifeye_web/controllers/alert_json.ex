defmodule NotifeyeWeb.AlertJSON do
  alias Notifeye.Alerts.Alert

  @doc """
  Renders a list of alerts.
  """
  def index(%{alerts: alerts}) do
    %{data: for(alert <- alerts, do: data(alert))}
  end

  @doc """
  Renders a single alert.
  """
  def show(%{alert: alert}) do
    %{data: data(alert)}
  end

  defp data(%Alert{} = alert) do
    %{
      id: alert.id,
      alert_id: alert.alert_id,
      title: alert.title,
      description: alert.description,
      definition_id: alert.definition_id,
      severity: alert.severity,
      tags: alert.tags,
      samples: alert.samples
    }
  end
end
