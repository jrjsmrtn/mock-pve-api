# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApiTest do
  use ExUnit.Case, async: false

  describe "reset_state/0" do
    test "delegates to State.reset" do
      MockPveApi.State.create_pool("test-pool", %{})
      assert MockPveApi.reset_state() == :ok
      assert MockPveApi.State.get_pools() == []
    end
  end
end
