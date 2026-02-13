# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

# Test Helper for MockPveApi
# Sets up the test environment and provides common testing utilities

ExUnit.start()

# Start the application for integration testing
Application.ensure_all_started(:mock_pve_api)

# Give the application a moment to start up
:timer.sleep(100)
