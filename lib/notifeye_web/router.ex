defmodule NotifeyeWeb.Router do
  use NotifeyeWeb, :router

  import NotifeyeWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {NotifeyeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_current_scope_for_api_user
  end

  pipeline :require_admin do
    plug NotifeyeWeb.Plugs.Authorize, :admin
  end

  pipeline :require_lead do
    plug NotifeyeWeb.Plugs.Authorize, :lead
  end

  scope "/", NotifeyeWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api", NotifeyeWeb do
    pipe_through :api

    scope "/alerts" do
      get "/", AlertController, :index
      post "/", AlertController, :create
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:notifeye, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: NotifeyeWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", NotifeyeWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{NotifeyeWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", NotifeyeWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{NotifeyeWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new

      live "/alerts", AlertLive.Index, :index
      live "/alerts/new", AlertLive.Form, :new
      live "/alerts/:id", AlertLive.Show, :show
      live "/alerts/:id/edit", AlertLive.Form, :edit
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  scope "/admin", NotifeyeWeb do
    pipe_through :browser

    live_session :admin,
      on_mount: [{NotifeyeWeb.UserAuth, :ensure_admin}] do
      live "/alert-descriptions", AdminLive.AlertDescriptions.Index, :index
      live "/alert-descriptions/:id", AdminLive.AlertDescriptions.Show, :show
      live "/alert-descriptions/:id/edit", AdminLive.AlertDescriptions.Edit, :edit
    end
  end
end
