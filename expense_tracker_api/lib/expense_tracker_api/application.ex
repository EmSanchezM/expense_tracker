defmodule ExpenseTrackerApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExpenseTrackerApiWeb.Telemetry,
      ExpenseTrackerApi.Repo,
      {DNSCluster, query: Application.get_env(:expense_tracker_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ExpenseTrackerApi.PubSub},
      # Start a worker by calling: ExpenseTrackerApi.Worker.start_link(arg)
      # {ExpenseTrackerApi.Worker, arg},
      # Start to serve requests, typically the last entry
      ExpenseTrackerApiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExpenseTrackerApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExpenseTrackerApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
