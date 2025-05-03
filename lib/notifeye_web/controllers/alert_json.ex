defmodule NotifeyeWeb.AlertJSON do
  alias Notifeye.Monitoring.Alert

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
      logz_id: alert.logz_id,
      alert_title: alert.alert_title,
      alert_description: alert.alert_description,
      alert_severity: alert.alert_severity,
      alert_event_samples: alert.alert_event_samples,
      alert_tags: alert.alert_tags,
      start: alert.start,
      end: alert.end
    }
  end
end
