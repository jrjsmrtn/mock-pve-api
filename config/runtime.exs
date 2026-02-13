import Config

# Runtime configuration for Mock PVE API Server
# This configuration is evaluated at runtime and can use environment variables

config :mock_pve_api,
  # Server configuration - read from environment at runtime
  port: System.get_env("MOCK_PVE_PORT", "8006") |> String.to_integer(),
  host: System.get_env("MOCK_PVE_HOST", "0.0.0.0"),

  # SSL/TLS configuration - read from environment at runtime
  ssl_enabled: System.get_env("MOCK_PVE_SSL_ENABLED", "false") == "true",
  ssl_keyfile: System.get_env("MOCK_PVE_SSL_KEYFILE", "certs/server.key"),
  ssl_certfile: System.get_env("MOCK_PVE_SSL_CERTFILE", "certs/server.crt"),
  ssl_cacertfile: System.get_env("MOCK_PVE_SSL_CACERTFILE"),

  # PVE version simulation - read from environment at runtime
  pve_version: System.get_env("MOCK_PVE_VERSION", "8.3"),

  # Feature toggles - read from environment at runtime
  enable_sdn: System.get_env("MOCK_PVE_ENABLE_SDN", "true") == "true",
  enable_firewall: System.get_env("MOCK_PVE_ENABLE_FIREWALL", "true") == "true",
  enable_backup_providers: System.get_env("MOCK_PVE_ENABLE_BACKUP_PROVIDERS", "true") == "true",

  # Simulation options - read from environment at runtime
  response_delay_ms: System.get_env("MOCK_PVE_DELAY", "0") |> String.to_integer(),
  error_rate: System.get_env("MOCK_PVE_ERROR_RATE", "0") |> String.to_integer()

# Logging level - read from environment at runtime  
case System.get_env("MOCK_PVE_LOG_LEVEL", "info") do
  "debug" -> config :logger, level: :debug
  "info" -> config :logger, level: :info
  "warn" -> config :logger, level: :warning
  "error" -> config :logger, level: :error
  _ -> config :logger, level: :info
end
