# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :voicescribe_api,
  generators: [timestamp_type: :utc_datetime]

# Configure endpoint
config :voicescribe_api, VoiceScribeAPIServer.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [
      json: VoiceScribeAPIServer.ErrorJSON
    ],
    layout: false
  ],
  pubsub_server: VoiceScribeAPI.PubSub



# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure ExAws for AWS services
config :ex_aws,
  region: System.get_env("AWS_REGION", "eu-central-1"),
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  # Configure DynamoDB specifically
  dynamodb: [
    region: System.get_env("AWS_REGION", "eu-central-1"),
    scheme: "https://",
    host: "dynamodb.#{System.get_env("AWS_REGION", "eu-central-1")}.amazonaws.com",
    port: 443
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
