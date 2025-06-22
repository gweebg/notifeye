defmodule NotifeyeWeb.AlertLiveTest do
  use NotifeyeWeb.ConnCase

  import Phoenix.LiveViewTest
  import Notifeye.MonitoringFixtures

  @create_attrs %{start: "2025-06-16T10:29:00Z", end: "2025-06-16T10:29:00Z", logz_id: "some logz_id", alert_title: "some alert_title", alert_description: "some alert_description", alert_severity: "some alert_severity", alert_event_samples: "some alert_event_samples", alert_tags: ["option1", "option2"]}
  @update_attrs %{start: "2025-06-17T10:29:00Z", end: "2025-06-17T10:29:00Z", logz_id: "some updated logz_id", alert_title: "some updated alert_title", alert_description: "some updated alert_description", alert_severity: "some updated alert_severity", alert_event_samples: "some updated alert_event_samples", alert_tags: ["option1"]}
  @invalid_attrs %{start: nil, end: nil, logz_id: nil, alert_title: nil, alert_description: nil, alert_severity: nil, alert_event_samples: nil, alert_tags: []}

  setup :register_and_log_in_user

  defp create_alert(%{scope: scope}) do
    alert = alert_fixture(scope)

    %{alert: alert}
  end

  describe "Index" do
    setup [:create_alert]

    test "lists all alerts", %{conn: conn, alert: alert} do
      {:ok, _index_live, html} = live(conn, ~p"/alerts")

      assert html =~ "Listing Alerts"
      assert html =~ alert.logz_id
    end

    test "saves new alert", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/alerts")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Alert")
               |> render_click()
               |> follow_redirect(conn, ~p"/alerts/new")

      assert render(form_live) =~ "New Alert"

      assert form_live
             |> form("#alert-form", alert: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#alert-form", alert: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/alerts")

      html = render(index_live)
      assert html =~ "Alert created successfully"
      assert html =~ "some logz_id"
    end

    test "updates alert in listing", %{conn: conn, alert: alert} do
      {:ok, index_live, _html} = live(conn, ~p"/alerts")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#alerts-#{alert.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/alerts/#{alert}/edit")

      assert render(form_live) =~ "Edit Alert"

      assert form_live
             |> form("#alert-form", alert: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#alert-form", alert: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/alerts")

      html = render(index_live)
      assert html =~ "Alert updated successfully"
      assert html =~ "some updated logz_id"
    end

    test "deletes alert in listing", %{conn: conn, alert: alert} do
      {:ok, index_live, _html} = live(conn, ~p"/alerts")

      assert index_live |> element("#alerts-#{alert.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#alerts-#{alert.id}")
    end
  end

  describe "Show" do
    setup [:create_alert]

    test "displays alert", %{conn: conn, alert: alert} do
      {:ok, _show_live, html} = live(conn, ~p"/alerts/#{alert}")

      assert html =~ "Show Alert"
      assert html =~ alert.logz_id
    end

    test "updates alert and returns to show", %{conn: conn, alert: alert} do
      {:ok, show_live, _html} = live(conn, ~p"/alerts/#{alert}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/alerts/#{alert}/edit?return_to=show")

      assert render(form_live) =~ "Edit Alert"

      assert form_live
             |> form("#alert-form", alert: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#alert-form", alert: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/alerts/#{alert}")

      html = render(show_live)
      assert html =~ "Alert updated successfully"
      assert html =~ "some updated logz_id"
    end
  end
end
