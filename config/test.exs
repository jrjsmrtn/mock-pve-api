import Config

# Test configuration
config :mock_pve_api,
  port: 8007,  # Different port for tests to avoid conflicts
  host: "127.0.0.1",
  pve_version: "8.3",
  response_delay_ms: 0,  # No delays in tests
  error_rate: 0          # No simulated errors in tests

# Reduce log output during tests
config :logger, level: :warn