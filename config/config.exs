# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :simple_oban,
  ecto_repos: [SimpleOban.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :simple_oban, SimpleObanWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SimpleObanWeb.ErrorHTML, json: SimpleObanWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SimpleOban.PubSub,
  live_view: [signing_salt: "EbPWxBnl"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :simple_oban, SimpleOban.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  simple_oban: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  simple_oban: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :simple_oban, Oban,
  engine: Oban.Pro.Engines.Smart,
  repo: SimpleOban.Repo,
  notifier: Oban.Notifiers.PG,
  # This is a subset of the 20+ queues we have
  # But this provider queue is our most busy/complex one
  queues: [
    sport_provider: [
      local_limit: 25,
      global_limit: [allowed: 1, partition: [:worker, args: :event_id]]
    ],
    scheduler: 5
  ],
  plugins: [
    Oban.Pro.Plugins.DynamicCron,
    Oban.Pro.Plugins.DynamicLifeline,
    # {Oban.Plugins.Pruner, max_age: 30}
    Oban.Plugins.Pruner
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
