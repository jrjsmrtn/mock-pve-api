# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

import Config

# Test configuration
config :mock_pve_api,
  # Different port for tests to avoid conflicts
  port: 8007,
  host: "127.0.0.1",
  pve_version: "8.3",
  # No delays in tests
  response_delay_ms: 0,
  # No simulated errors in tests
  error_rate: 0

# Reduce log output during tests
config :logger, level: :warning
