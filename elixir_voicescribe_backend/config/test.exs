import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :voicescribe_api, VoiceScribeAPIServer.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ATPUu0nOC9+I07qYCYkagS9dNni4C1evouCgS1tE9+ySIEtciBA014sUQWjCAP+I",
  server: false

# Configure AWS for tests (using mock values if environment variables aren't set)
config :ex_aws,
  region: "us-east-1",
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID", "AKIAIOSFODNN7EXAMPLE"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY", "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
