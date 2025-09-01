import Config

# Production configuration
config :mock_pve_api,
  port: 8006,
  host: "0.0.0.0",
  pve_version: "8.3"

# Reduce log level in production
config :logger, level: :info