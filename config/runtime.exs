# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

import Config

# Runtime configuration for Mock PVE API Server
# Only override values when environment variables are explicitly set,
# so that config/test.exs and config/dev.exs values are preserved.

if port = System.get_env("MOCK_PVE_PORT") do
  config :mock_pve_api, port: String.to_integer(port)
end

if host = System.get_env("MOCK_PVE_HOST") do
  config :mock_pve_api, host: host
end

if version = System.get_env("MOCK_PVE_VERSION") do
  config :mock_pve_api, pve_version: version
end

# SSL/TLS configuration
if System.get_env("MOCK_PVE_SSL_ENABLED") do
  config :mock_pve_api,
    ssl_enabled: System.get_env("MOCK_PVE_SSL_ENABLED") == "true",
    ssl_keyfile: System.get_env("MOCK_PVE_SSL_KEYFILE", "certs/server.key"),
    ssl_certfile: System.get_env("MOCK_PVE_SSL_CERTFILE", "certs/server.crt"),
    ssl_cacertfile: System.get_env("MOCK_PVE_SSL_CACERTFILE")
end

# Feature toggles - only override if explicitly set
if val = System.get_env("MOCK_PVE_ENABLE_SDN") do
  config :mock_pve_api, enable_sdn: val == "true"
end

if val = System.get_env("MOCK_PVE_ENABLE_FIREWALL") do
  config :mock_pve_api, enable_firewall: val == "true"
end

if val = System.get_env("MOCK_PVE_ENABLE_BACKUP_PROVIDERS") do
  config :mock_pve_api, enable_backup_providers: val == "true"
end

# Simulation options - only override if explicitly set
if val = System.get_env("MOCK_PVE_DELAY") do
  config :mock_pve_api, response_delay_ms: String.to_integer(val)
end

if val = System.get_env("MOCK_PVE_ERROR_RATE") do
  config :mock_pve_api, error_rate: String.to_integer(val)
end

# Logging level
if log_level = System.get_env("MOCK_PVE_LOG_LEVEL") do
  case log_level do
    "debug" -> config :logger, level: :debug
    "info" -> config :logger, level: :info
    "warn" -> config :logger, level: :warning
    "error" -> config :logger, level: :error
    _ -> nil
  end
end
