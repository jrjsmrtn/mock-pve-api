# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Capabilities do
  @moduledoc """
  Version-aware capability system for the Mock PVE Server.

  This module defines which features are available in different PVE versions,
  enabling realistic testing of version-specific functionality and graceful
  degradation when features are not available.
  """

  @type version() :: String.t()
  @type capability() :: atom()

  # Version capability matrix - defines which features are available in each version
  @capabilities %{
    # PVE 7.x series capabilities
    "7.0" => [
      :basic_virtualization,
      :containers,
      :storage_basic,
      :cluster_basic,
      :user_management_basic,
      :backup_basic
    ],
    "7.1" => [
      :basic_virtualization,
      :containers,
      :storage_basic,
      :cluster_basic,
      :user_management_basic,
      :backup_basic,
      :ceph_octopus
    ],
    "7.2" => [
      :basic_virtualization,
      :containers,
      :storage_basic,
      :cluster_basic,
      :user_management_basic,
      :backup_basic,
      :ceph_octopus,
      :network_improvements
    ],
    "7.3" => [
      :basic_virtualization,
      :containers,
      :storage_basic,
      :cluster_basic,
      :user_management_basic,
      :backup_basic,
      :ceph_octopus,
      :network_improvements,
      :ceph_pacific
    ],
    "7.4" => [
      :basic_virtualization,
      :containers,
      :storage_basic,
      :cluster_basic,
      :user_management_basic,
      :backup_basic,
      :ceph_octopus,
      :network_improvements,
      :ceph_pacific,
      :cgroup_v1,
      :pre_upgrade_validation
    ],

    # PVE 8.x series capabilities
    "8.0" => [
      :basic_virtualization,
      :containers,
      :storage_basic,
      :cluster_basic,
      :user_management_basic,
      :backup_basic,
      :ceph_quincy,
      :sdn_tech_preview,
      :realm_sync_jobs,
      :resource_mappings,
      :acl_improvements,
      :tui_installer,
      :cgroup_v2
    ],
    "8.1" => [
      :basic_virtualization,
      :containers,
      :storage_basic,
      :cluster_basic,
      :user_management_basic,
      :backup_basic,
      :ceph_quincy,
      :sdn_stable,
      :realm_sync_jobs,
      :resource_mappings,
      :acl_improvements,
      :tui_installer,
      :cgroup_v2,
      :notification_endpoints,
      :notification_filters
    ],
    "8.2" => [
      :basic_virtualization,
      :containers,
      :storage_basic,
      :cluster_basic,
      :user_management_basic,
      :backup_basic,
      :ceph_quincy,
      :ceph_reef,
      :sdn_stable,
      :realm_sync_jobs,
      :resource_mappings,
      :acl_improvements,
      :tui_installer,
      :cgroup_v2,
      :notification_endpoints,
      :notification_filters,
      :vmware_import_wizard,
      :auto_install_assistant,
      :backup_providers
    ],
    "8.3" => [
      :basic_virtualization,
      :containers,
      :storage_basic,
      :cluster_basic,
      :user_management_basic,
      :backup_basic,
      :ceph_quincy,
      :ceph_reef,
      :sdn_stable,
      :realm_sync_jobs,
      :resource_mappings,
      :acl_improvements,
      :tui_installer,
      :cgroup_v2,
      :notification_endpoints,
      :notification_filters,
      :vmware_import_wizard,
      :auto_install_assistant,
      :backup_providers,
      :ova_import_improvements,
      :kernel_6_11_opt_in
    ],

    # PVE 9.x series capabilities
    "9.0" => [
      :basic_virtualization,
      :containers,
      :storage_basic,
      :cluster_basic,
      :user_management_basic,
      :backup_basic,
      :ceph_reef,
      :ceph_squid,
      :sdn_stable,
      :sdn_fabrics,
      :realm_sync_jobs,
      :resource_mappings,
      :acl_improvements,
      :tui_installer,
      :cgroup_v2,
      :notification_endpoints,
      :notification_filters,
      :vmware_import_wizard,
      :auto_install_assistant,
      :backup_providers,
      :backup_provider_api,
      :ha_resource_affinity,
      :lvm_snapshots,
      :zfs_raidz_expansion,
      :openfabric_routing,
      :ospf_routing,
      :parallel_backup_restore,
      :mobile_interface_v2,
      :debian_13_base
    ]
  }

  @doc """
  Checks if a capability is available in the given PVE version.

  ## Examples

      iex> MockPveApi.Capabilities.has_capability?("8.0", :sdn_tech_preview)
      true
      
      iex> MockPveApi.Capabilities.has_capability?("7.4", :sdn_tech_preview)  
      false
  """
  @spec has_capability?(version(), capability()) :: boolean()
  def has_capability?(version, capability) do
    capabilities = get_capabilities(version)

    if capability in capabilities do
      true
    else
      # :sdn_stable is a superset of :sdn_tech_preview — versions with
      # :sdn_stable also support endpoints gated on :sdn_tech_preview
      capability == :sdn_tech_preview and :sdn_stable in capabilities
    end
  end

  @doc """
  Alias for has_capability?/2 for backward compatibility with tests.
  """
  @spec version_supports?(version(), capability()) :: boolean()
  def version_supports?(version, capability) do
    has_capability?(version, capability)
  end

  @doc """
  Gets all capabilities available for a given PVE version.

  ## Examples

      iex> MockPveApi.Capabilities.get_capabilities("8.0")
      [:basic_virtualization, :containers, ...]
  """
  @spec get_capabilities(version()) :: [capability()]
  def get_capabilities(version) do
    case @capabilities[version] do
      nil ->
        # Try to find capabilities for base version (e.g., "7.4.1" -> "7.4")
        base_version = extract_base_version(version)

        case @capabilities[base_version] do
          nil ->
            # If base version not found, find closest lower version
            find_closest_version_capabilities(version)

          capabilities ->
            capabilities
        end

      capabilities ->
        capabilities
    end
  end

  # Helper function to extract base version from patch versions and pre-releases
  defp extract_base_version(version) do
    # Handle pre-release versions like "8.0-rc1", "8.1-beta2"
    clean_version = version |> String.split("-") |> hd()

    case String.split(clean_version, ".") do
      [major, minor | _] -> "#{major}.#{minor}"
      _ -> clean_version
    end
  end

  # Find capabilities for the closest lower or equal version
  defp find_closest_version_capabilities(version) do
    case parse_version(version) do
      {:ok, target_version} ->
        @capabilities
        |> Enum.filter(fn {v, _caps} ->
          case parse_version(v) do
            {:ok, parsed_v} -> version_lte(parsed_v, target_version)
            _ -> false
          end
        end)
        |> Enum.max_by(
          fn {v, _caps} ->
            case parse_version(v) do
              {:ok, parsed_v} -> parsed_v
              _ -> {0, 0}
            end
          end,
          fn -> {"7.0", @capabilities["7.0"]} end
        )
        |> elem(1)

      _ ->
        # Default to oldest version for invalid versions
        @capabilities["7.0"]
    end
  end

  # Parse version string to tuple for comparison
  defp parse_version(version) do
    try do
      # Clean pre-release suffixes like "8.0-rc1" -> "8.0"
      clean_version = version |> String.split("-") |> hd()

      case String.split(clean_version, ".") |> Enum.map(&String.to_integer/1) do
        [major, minor] -> {:ok, {major, minor}}
        [major, minor | _] -> {:ok, {major, minor}}
        _ -> :error
      end
    rescue
      _ -> :error
    end
  end

  # Check if version1 <= version2
  defp version_lte({maj1, min1}, {maj2, min2}) do
    maj1 < maj2 or (maj1 == maj2 and min1 <= min2)
  end

  @doc """
  Checks if an endpoint is supported in the given PVE version.

  Delegates to `MockPveApi.EndpointMatrix` (generated from pve-openapi specs).
  Endpoints not found in the matrix are assumed supported (e.g. `/api2/json/version`).

  ## Examples

      iex> MockPveApi.Capabilities.endpoint_supported?("8.0", "/api2/json/cluster/sdn/zones")
      true

      iex> MockPveApi.Capabilities.endpoint_supported?("7.4", "/api2/json/cluster/sdn/zones")
      true
  """
  @spec endpoint_supported?(version(), String.t()) :: boolean()
  def endpoint_supported?(version, endpoint_path) do
    # Normalize version to "major.minor" for matrix lookup
    base_version = extract_base_version(version)

    # If the endpoint exists in *any* version in the matrix, gate it;
    # otherwise it's a non-API endpoint (e.g. parameterized or custom) — allow it.
    if endpoint_in_matrix?(endpoint_path) do
      Enum.any?([:get, :post, :put, :delete], fn method ->
        MockPveApi.EndpointMatrix.available?(endpoint_path, method, base_version)
      end)
    else
      true
    end
  end

  # Check if this path exists in any version's endpoint set (for any HTTP method).
  defp endpoint_in_matrix?(path) do
    Enum.any?([:get, :post, :put, :delete], fn method ->
      MockPveApi.EndpointMatrix.added_in(path, method) != nil
    end)
  end

  @doc """
  Gets version information for API responses based on PVE version.
  """
  @spec get_version_info(version()) :: map()
  def get_version_info("7." <> _ = version) do
    %{
      version: version,
      release: "7.4",
      repoid: "d7b7b6e9",
      keyboard: "en-us"
    }
  end

  def get_version_info("8.0") do
    %{
      version: "8.0",
      release: "8.0",
      repoid: "f123456a",
      keyboard: "en-us"
    }
  end

  def get_version_info("8.1") do
    %{
      version: "8.1",
      release: "8.1",
      repoid: "f123456b",
      keyboard: "en-us"
    }
  end

  def get_version_info("8.2") do
    %{
      version: "8.2",
      release: "8.2",
      repoid: "f123456c",
      keyboard: "en-us"
    }
  end

  def get_version_info("8.3") do
    %{
      version: "8.3",
      release: "8.3",
      repoid: "f123456d",
      keyboard: "en-us"
    }
  end

  def get_version_info("9.0") do
    %{
      version: "9.0-2",
      release: "9.0",
      repoid: "5fc0b8d1",
      keyboard: "en-us",
      console: "xtermjs"
    }
  end

  def get_version_info("9." <> _ = version) do
    %{
      version: version,
      release: "9.0",
      repoid: "5fc0b8d1",
      keyboard: "en-us",
      console: "xtermjs"
    }
  end

  def get_version_info(_) do
    # Default to 9.0 for unknown versions (latest)
    get_version_info("9.0")
  end

  @doc """
  Lists all supported PVE versions.
  """
  @spec supported_versions() :: [version()]
  def supported_versions do
    Map.keys(@capabilities) |> Enum.sort()
  end

  @doc """
  Gets feature differences between two versions.

  Returns {:ok, added_features, removed_features} or {:error, reason}.
  """
  @spec version_diff(version(), version()) ::
          {:ok, [capability()], [capability()]} | {:error, String.t()}
  def version_diff(from_version, to_version) do
    with from_caps when is_list(from_caps) <- @capabilities[from_version],
         to_caps when is_list(to_caps) <- @capabilities[to_version] do
      added = to_caps -- from_caps
      removed = from_caps -- to_caps

      {:ok, added, removed}
    else
      nil -> {:error, "Unknown version"}
    end
  end
end
