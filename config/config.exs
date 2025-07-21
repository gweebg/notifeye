# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :notifeye, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [
    processing: 10,
    notifier: [limit: 10, dispatch_cooldown: 100]
  ],
  repo: Notifeye.Repo

config :notifeye, :scopes,
  user: [
    default: true,
    module: Notifeye.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Notifeye.AccountsFixtures,
    test_login_helper: :register_and_log_in_user
  ]

config :notifeye,
  ecto_repos: [Notifeye.Repo],
  generators: [timestamp_type: :utc_datetime],
  logz_base_url: System.get_env("LOGZ_BASE_URL", "https://api.logz.io/v2"),
  logz_api_key: System.get_env("LOGZ_API_KEY")

# Configures the endpoint
config :notifeye, NotifeyeWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: NotifeyeWeb.ErrorHTML, json: NotifeyeWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Notifeye.PubSub,
  live_view: [signing_salt: "6wLl8MR+"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :notifeye, Notifeye.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  notifeye: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.9",
  notifeye: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :request_logger]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :flop, repo: Notifeye.Repo

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
