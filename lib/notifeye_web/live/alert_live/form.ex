defmodule NotifeyeWeb.AlertLive.Form do
  use NotifeyeWeb, :live_view

  alias Notifeye.Monitoring
  alias Notifeye.Monitoring.Alert

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage alert records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="alert-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:logz_id]} type="text" label="Logz" />
        <.input field={@form[:alert_title]} type="text" label="Alert title" />
        <.input field={@form[:alert_description]} type="text" label="Alert description" />
        <.input field={@form[:alert_severity]} type="text" label="Alert severity" />
        <.input field={@form[:alert_event_samples]} type="text" label="Alert event samples" />
        <.input
          field={@form[:alert_tags]}
          type="select"
          multiple
          label="Alert tags"
          options={[{"Option 1", "option1"}, {"Option 2", "option2"}]}
        />
        <.input field={@form[:start]} type="datetime-local" label="Start" />
        <.input field={@form[:end]} type="datetime-local" label="End" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Alert</.button>
          <.button navigate={return_path(@current_scope, @return_to, @alert)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    alert = Monitoring.get_alert!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Alert")
    |> assign(:alert, alert)
    |> assign(:form, to_form(Monitoring.change_alert(socket.assigns.current_scope, alert)))
  end

  defp apply_action(socket, :new, _params) do
    alert = %Alert{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Alert")
    |> assign(:alert, alert)
    |> assign(:form, to_form(Monitoring.change_alert(socket.assigns.current_scope, alert)))
  end

  @impl true
  def handle_event("validate", %{"alert" => alert_params}, socket) do
    changeset =
      Monitoring.change_alert(socket.assigns.current_scope, socket.assigns.alert, alert_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"alert" => alert_params}, socket) do
    save_alert(socket, socket.assigns.live_action, alert_params)
  end

  defp save_alert(socket, :edit, alert_params) do
    case Monitoring.update_alert(socket.assigns.current_scope, socket.assigns.alert, alert_params) do
      {:ok, alert} ->
        {:noreply,
         socket
         |> put_flash(:info, "Alert updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, alert)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_alert(socket, :new, alert_params) do
    case Monitoring.create_alert(socket.assigns.current_scope, alert_params) do
      {:ok, alert} ->
        {:noreply,
         socket
         |> put_flash(:info, "Alert created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, alert)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _alert), do: ~p"/alerts"
  defp return_path(_scope, "show", alert), do: ~p"/alerts/#{alert}"
end
