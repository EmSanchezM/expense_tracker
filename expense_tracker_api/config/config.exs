# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :expense_tracker_api,
  ecto_repos: [ExpenseTrackerApi.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :expense_tracker_api, ExpenseTrackerApiWeb.Endpoint,
  url: [host: System.get_env("PHX_HOST") || "localhost" ],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ExpenseTrackerApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ExpenseTrackerApi.PubSub,
  live_view: [signing_salt: "NEOmdwak"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :expense_tracker_api, ExpenseTrackerApi.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures Guardian
config :expense_tracker_api, ExpenseTrackerApi.Accounts.Guardian,
  issuer: "expense_tracker_api",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY") || "your-secret-key-here-change-in-production"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
