# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

import Config

# Development configuration
config :mock_pve_api,
  port: 8006,
  host: "127.0.0.1",
  pve_version: "8.3"

# Enable debug logging in development
config :logger, level: :debug
