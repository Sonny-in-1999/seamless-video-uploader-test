defmodule CutTheCrab.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CutTheCrabWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:cut_the_crab, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CutTheCrab.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: CutTheCrab.Finch},
      # Start a worker by calling: CutTheCrab.Worker.start_link(arg)
      # {CutTheCrab.Worker, arg},
      # Start to serve requests, typically the last entry
      CutTheCrabWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CutTheCrab.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CutTheCrabWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
