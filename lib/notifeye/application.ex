defmodule Notifeye.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NotifeyeWeb.Telemetry,
      Notifeye.Repo,
      {DNSCluster, query: Application.get_env(:notifeye, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:notifeye, Oban)},
      {Phoenix.PubSub, name: Notifeye.PubSub},
      # Start a worker by calling: Notifeye.Worker.start_link(arg)
      # {Notifeye.Worker, arg},
      # Start to serve requests, typically the last entry
      NotifeyeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Notifeye.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NotifeyeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
