# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Category do
  @moduledoc """
  Behaviour for PVE API coverage category sub-modules.

  Each sub-module represents a PVE API category (e.g., nodes, VMs, storage)
  and provides its endpoint definitions. The coordinator (`MockPveApi.Coverage`)
  aggregates all sub-modules at compile time.
  """

  @callback category() :: atom()
  @callback endpoints() :: %{String.t() => MockPveApi.Coverage.endpoint_info()}
end
