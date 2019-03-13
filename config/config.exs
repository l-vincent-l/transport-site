# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :transport, :environment, Mix.env

# Configures the endpoint
config :transport, TransportWeb.Endpoint,
  url: [host: "127.0.0.1"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [
    view: TransportWeb.ErrorView,
    layout: {TransportWeb.LayoutView, "app.html"},
    accepts: ~w(html json)
  ],
  pubsub: [name: Transport.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures format encoders
config :phoenix, :format_encoders,
  html: Phoenix.Template.HTML,
  json: Poison

# Configures Elixir's Logger
config :logger,
  handle_otp_reports: true,
  handle_sasl_reports: true,
  translators: [
    {Support.Logger.Translator, :translate},
    {Logger.Translator, :translate}
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :scrivener_html,
  routes_helper: TransportWeb.Router.Helpers

# Allow to have Markdown templates
config :phoenix, :template_engines,
  md: PhoenixMarkdown.Engine

config :phoenix_markdown, :server_tags, :all

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: Mix.env,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!,
  tags: %{
    env: "production"
  },
  included_environments: [:prod]


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "datagouvfr.exs"
import_config "database.exs"
import_config "gtfs_validator.exs"
import_config "mailjet.exs"
import_config "mailchimp.exs"
import_config "#{Mix.env}.exs"
