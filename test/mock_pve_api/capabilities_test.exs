# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.CapabilitiesTest do
  use ExUnit.Case, async: true

  alias MockPveApi.Capabilities

  # --- get_capabilities/1 ---

  describe "get_capabilities/1" do
    test "returns capabilities for exact version match" do
      caps = Capabilities.get_capabilities("8.0")
      assert is_list(caps)
      assert :basic_virtualization in caps
      assert :sdn_tech_preview in caps
    end

    test "returns capabilities for 7.0" do
      caps = Capabilities.get_capabilities("7.0")
      assert :basic_virtualization in caps
      refute :sdn_tech_preview in caps
    end

    test "returns capabilities for 9.0" do
      caps = Capabilities.get_capabilities("9.0")
      assert :ha_resource_affinity in caps
      assert :sdn_fabrics in caps
      assert :debian_13_base in caps
    end

    test "falls back to base version for patch version like 7.4.1" do
      caps = Capabilities.get_capabilities("7.4.1")
      expected = Capabilities.get_capabilities("7.4")
      assert caps == expected
    end

    test "falls back to base version for pre-release like 8.0-rc1" do
      caps = Capabilities.get_capabilities("8.0-rc1")
      expected = Capabilities.get_capabilities("8.0")
      assert caps == expected
    end

    test "finds closest lower version for unknown version like 7.5" do
      caps = Capabilities.get_capabilities("7.5")
      # 7.5 > 7.4, so should get 7.4 capabilities
      expected = Capabilities.get_capabilities("7.4")
      assert caps == expected
    end

    test "returns 7.0 capabilities for completely invalid version" do
      caps = Capabilities.get_capabilities("invalid")
      expected = Capabilities.get_capabilities("7.0")
      assert caps == expected
    end
  end

  # --- has_capability?/2 ---

  describe "has_capability?/2" do
    test "returns true for present capability" do
      assert Capabilities.has_capability?("8.0", :sdn_tech_preview) == true
    end

    test "returns false for absent capability" do
      assert Capabilities.has_capability?("7.4", :sdn_tech_preview) == false
    end

    test "sdn_stable is superset of sdn_tech_preview" do
      # 8.1 has :sdn_stable but not :sdn_tech_preview directly
      assert Capabilities.has_capability?("8.1", :sdn_tech_preview) == true
      assert Capabilities.has_capability?("8.1", :sdn_stable) == true
    end

    test "sdn_tech_preview check on version without any SDN" do
      assert Capabilities.has_capability?("7.4", :sdn_tech_preview) == false
    end

    test "cross-version capability check" do
      refute Capabilities.has_capability?("7.0", :ceph_pacific)
      assert Capabilities.has_capability?("7.3", :ceph_pacific)
    end
  end

  # --- version_supports?/2 (alias) ---

  describe "version_supports?/2" do
    test "works as alias for has_capability?" do
      assert Capabilities.version_supports?("8.0", :sdn_tech_preview) ==
               Capabilities.has_capability?("8.0", :sdn_tech_preview)
    end
  end

  # --- endpoint_supported?/2 ---
  # Now backed by EndpointMatrix (generated from pve-openapi ground-truth specs).

  describe "endpoint_supported?/2" do
    test "returns true for endpoints not in the matrix" do
      assert Capabilities.endpoint_supported?("7.0", "/api2/json/version") == true
    end

    test "SDN zones available since 7.0 per pve-openapi specs" do
      assert Capabilities.endpoint_supported?("7.0", "/api2/json/cluster/sdn/zones")
      assert Capabilities.endpoint_supported?("7.4", "/api2/json/cluster/sdn/zones")
      assert Capabilities.endpoint_supported?("8.0", "/api2/json/cluster/sdn/zones")
      assert Capabilities.endpoint_supported?("8.1", "/api2/json/cluster/sdn/zones")
    end

    test "notification endpoints require 8.1+" do
      assert Capabilities.endpoint_supported?("8.1", "/api2/json/cluster/notifications/endpoints")
      assert Capabilities.endpoint_supported?("9.0", "/api2/json/cluster/notifications/endpoints")
      refute Capabilities.endpoint_supported?("8.0", "/api2/json/cluster/notifications/endpoints")
      refute Capabilities.endpoint_supported?("7.4", "/api2/json/cluster/notifications/endpoints")
    end

    test "SDN fabrics require 9.0+" do
      assert Capabilities.endpoint_supported?("9.0", "/api2/json/cluster/sdn/fabrics")
      refute Capabilities.endpoint_supported?("8.3", "/api2/json/cluster/sdn/fabrics")
    end

    test "HA rules require 9.0+" do
      assert Capabilities.endpoint_supported?("9.0", "/api2/json/cluster/ha/rules")
      refute Capabilities.endpoint_supported?("8.3", "/api2/json/cluster/ha/rules")
    end
  end

  # --- get_version_info/1 ---

  describe "get_version_info/1" do
    test "returns info for 7.x versions" do
      info = Capabilities.get_version_info("7.4")
      assert info.version == "7.4"
      assert info.release == "7.4"
      assert is_binary(info.repoid)
    end

    test "returns info for 8.0" do
      info = Capabilities.get_version_info("8.0")
      assert info.version == "8.0"
      assert info.release == "8.0"
    end

    test "returns info for 8.1" do
      info = Capabilities.get_version_info("8.1")
      assert info.version == "8.1"
    end

    test "returns info for 8.2" do
      info = Capabilities.get_version_info("8.2")
      assert info.version == "8.2"
    end

    test "returns info for 8.3" do
      info = Capabilities.get_version_info("8.3")
      assert info.version == "8.3"
    end

    test "returns info for 9.0 with console field" do
      info = Capabilities.get_version_info("9.0")
      assert info.release == "9.0"
      assert info.console == "xtermjs"
    end

    test "returns info for 9.x wildcard" do
      info = Capabilities.get_version_info("9.1")
      assert info.release == "9.0"
      assert info.console == "xtermjs"
    end

    test "defaults to 9.0 for unknown versions" do
      info = Capabilities.get_version_info("99.0")
      assert info.release == "9.0"
    end
  end

  # --- supported_versions/0 ---

  describe "supported_versions/0" do
    test "returns sorted list of versions" do
      versions = Capabilities.supported_versions()
      assert is_list(versions)
      assert "7.0" in versions
      assert "9.0" in versions
      assert versions == Enum.sort(versions)
    end
  end

  # --- version_diff/2 ---

  describe "version_diff/2" do
    test "returns added and removed features" do
      {:ok, added, removed} = Capabilities.version_diff("7.4", "8.0")
      assert is_list(added)
      assert is_list(removed)
      assert :sdn_tech_preview in added
      assert :cgroup_v2 in added
      assert :cgroup_v1 in removed
    end

    test "returns error for unknown version" do
      assert {:error, "Unknown version"} = Capabilities.version_diff("99.0", "8.0")
      assert {:error, "Unknown version"} = Capabilities.version_diff("8.0", "99.0")
    end

    test "returns empty lists for same version" do
      {:ok, added, removed} = Capabilities.version_diff("8.0", "8.0")
      assert added == []
      assert removed == []
    end
  end
end
