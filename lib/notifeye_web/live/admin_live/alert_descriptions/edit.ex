defmodule NotifeyeWeb.AdminLive.AlertDescriptions.Edit do
  @moduledoc false

  use NotifeyeWeb, :live_view

  alias Notifeye.AlertDescriptions
  alias Notifeye.Monitoring
  alias Notifeye.Notifications

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    alert_description = AlertDescriptions.get_alert_description!(id)
    sample = Monitoring.get_alert_for_description!(id)

    changeset = AlertDescriptions.change_alert_description(alert_description)
    notification_groups = Notifications.list_notification_groups()

    socket =
      socket
      |> assign(:alert_description, alert_description)
      |> assign(:changeset, changeset)
      |> assign(:notification_groups, notification_groups)
      |> assign(:sample_alert, sample)
      |> assign(:test_result, "")

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"alert_description" => alert_description_params}, socket) do
    changeset =
      socket.assigns.alert_description
      |> AlertDescriptions.change_alert_description(alert_description_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"alert_description" => alert_description_params}, socket) do
    perform_save(socket, alert_description_params)
  end

  @impl true
  def handle_event("force_save", _params, socket) do
    # Get the current changeset values for force save
    changeset = socket.assigns.changeset

    # Convert changeset to params format
    alert_description_params =
      changeset.changes
      |> Enum.into(%{})
      |> Enum.map(fn {key, value} -> {to_string(key), value} end)
      |> Enum.into(%{})

    perform_save(socket, alert_description_params)
  end

  defp perform_save(socket, alert_description_params) do
    # add the last person that edited the description onto the description
    current_user = socket.assigns.current_scope.user

    alert_description_params =
      alert_description_params
      |> Map.put("edited_by", current_user.id)
      |> Map.put("verified", true)

    case AlertDescriptions.update_alert_description(
           socket.assigns.alert_description,
           alert_description_params
         ) do
      {:ok, _alert_description} ->
        {:noreply,
         socket
         |> put_flash(:info, "Alert description updated successfully")
         |> push_navigate(
           to: ~p"/admin/alert-descriptions/#{socket.assigns.alert_description.id}"
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("do_test", _params, socket) do
    %{changeset: changeset, sample_alert: alert} = socket.assigns

    pattern =
      case Map.get(changeset.changes, :pattern) do
        nil -> changeset.data.pattern
        value -> value
      end

    sample = alert.alert_event_samples

    result =
      pattern
      |> AlertDescriptions.maybe_match_samples(sample)

    {:noreply,
     socket
     |> assign(:test_result, result)}
  end

  @impl true
  def handle_event("clear_test", _params, socket) do
    {:noreply, socket |> assign(:test_result, "")}
  end

  defp state_options do
    [
      {"Enabled", "enabled"},
      {"Disabled", "disabled"},
      {"Group Only", "grouponly"}
    ]
  end
end
