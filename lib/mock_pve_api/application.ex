# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Application do
  @moduledoc """
  OTP Application for the Mock PVE Server.
  """

  use Application

  @impl true
  def start(_type, _args) do
    MockPveApi.start(:normal, [])
  end
end
