# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

import Config

# Mock PVE API Server configuration
config :mock_pve_api,
  # Server configuration
  port: System.get_env("MOCK_PVE_PORT", "8006") |> String.to_integer(),
  host: System.get_env("MOCK_PVE_HOST", "0.0.0.0"),

  # PVE version simulation (7.0, 7.1, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3, 9.0)
  pve_version: System.get_env("MOCK_PVE_VERSION", "8.3"),

  # Feature toggles
  enable_sdn: System.get_env("MOCK_PVE_ENABLE_SDN", "true") == "true",
  enable_firewall: System.get_env("MOCK_PVE_ENABLE_FIREWALL", "true") == "true",
  enable_backup_providers: System.get_env("MOCK_PVE_ENABLE_BACKUP_PROVIDERS", "true") == "true",

  # Simulation options
  response_delay_ms: System.get_env("MOCK_PVE_DELAY", "0") |> String.to_integer(),
  error_rate: System.get_env("MOCK_PVE_ERROR_RATE", "0") |> String.to_integer(),

  # Logging
  log_level: System.get_env("MOCK_PVE_LOG_LEVEL", "info") |> String.to_atom()

# Set log level
config :logger, level: :info

# Environment-specific configuration
import_config "#{config_env()}.exs"
