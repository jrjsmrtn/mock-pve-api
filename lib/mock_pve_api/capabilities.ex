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

  # Endpoint to capability mapping
  @endpoint_capabilities %{
    # SDN endpoints (8.0+)
    "/api2/json/cluster/sdn/zones" => :sdn_tech_preview,
    "/api2/json/cluster/sdn/vnets" => :sdn_tech_preview,
    "/api2/json/cluster/sdn/subnets" => :sdn_tech_preview,
    "/api2/json/cluster/sdn/controllers" => :sdn_stable,

    # Realm sync endpoints (8.0+)
    "/api2/json/access/domains/{realm}/sync" => :realm_sync_jobs,
    "/api2/json/cluster/jobs/realm-sync" => :realm_sync_jobs,

    # Resource mapping endpoints (8.0+)
    "/api2/json/cluster/mapping/pci" => :resource_mappings,
    "/api2/json/cluster/mapping/usb" => :resource_mappings,

    # Enhanced notification endpoints (8.1+)
    "/api2/json/cluster/notifications/endpoints" => :notification_endpoints,
    "/api2/json/cluster/notifications/targets" => :notification_endpoints,
    "/api2/json/cluster/notifications/filters" => :notification_filters,

    # VMware import endpoints (8.2+)
    "/api2/json/nodes/{node}/storage/{storage}/import" => :vmware_import_wizard,
    "/api2/json/nodes/{node}/import-esxi" => :vmware_import_wizard,

    # Backup provider endpoints (8.2+)
    "/api2/json/cluster/backup-providers" => :backup_providers,
    "/api2/json/nodes/{node}/storage/{storage}/backup-providers" => :backup_providers,

    # PVE 9.x specific endpoints
    # SDN Fabric endpoints (9.0+)
    "/api2/json/cluster/sdn/fabrics" => :sdn_fabrics,
    "/api2/json/cluster/sdn/fabrics/{fabric_id}" => :sdn_fabrics,
    "/api2/json/cluster/sdn/fabrics/{fabric_id}/status" => :sdn_fabrics,
    "/api2/json/cluster/sdn/fabrics/{fabric_id}/routes" => :sdn_fabrics,
    "/api2/json/cluster/sdn/fabrics/{fabric_id}/openfabric" => :openfabric_routing,
    "/api2/json/cluster/sdn/fabrics/{fabric_id}/ospf" => :ospf_routing,

    # HA Resource Affinity endpoints (9.0+)
    "/api2/json/cluster/ha/affinity" => :ha_resource_affinity,
    "/api2/json/cluster/ha/affinity/{rule_id}" => :ha_resource_affinity,
    "/api2/json/cluster/ha/affinity/{rule_id}/status" => :ha_resource_affinity,
    "/api2/json/cluster/ha/affinity/violations" => :ha_resource_affinity,
    "/api2/json/cluster/ha/affinity/resolve" => :ha_resource_affinity,

    # LVM Snapshot endpoints (9.0+)
    "/api2/json/nodes/{node}/storage/{storage}/lvm/snapshots" => :lvm_snapshots,
    "/api2/json/nodes/{node}/storage/{storage}/lvm/snapshots/{snapshot_name}" => :lvm_snapshots,
    "/api2/json/nodes/{node}/storage/{storage}/lvm/volumes/{volume}/chain" => :lvm_snapshots,

    # ZFS RAIDZ Expansion endpoints (9.0+)
    "/api2/json/nodes/{node}/storage/zfs/raidz/expandable" => :zfs_raidz_expansion,
    "/api2/json/nodes/{node}/storage/zfs/{pool_name}/expansion-info" => :zfs_raidz_expansion,
    "/api2/json/nodes/{node}/storage/zfs/{pool_name}/expand" => :zfs_raidz_expansion,
    "/api2/json/nodes/{node}/storage/zfs/{pool_name}/expansion-status" => :zfs_raidz_expansion,

    # Enhanced Backup Provider API endpoints (9.0+)
    "/api2/json/cluster/backup-providers/{provider_id}/config" => :backup_provider_api,
    "/api2/json/cluster/backup-providers/{provider_id}/test" => :backup_provider_api,
    "/api2/json/cluster/backup-providers/{provider_id}/backup" => :backup_provider_api,
    "/api2/json/cluster/backup-providers/backups/{backup_id}" => :backup_provider_api,
    "/api2/json/cluster/backup-providers/backups/{backup_id}/restore" => :backup_provider_api
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
    capability in capabilities
  end

  @doc """
  Gets all capabilities available for a given PVE version.

  ## Examples

      iex> MockPveApi.Capabilities.get_capabilities("8.0")
      [:basic_virtualization, :containers, ...]
  """
  @spec get_capabilities(version()) :: [capability()]
  def get_capabilities(version) do
    @capabilities[version] || @capabilities["8.0"]
  end

  @doc """
  Checks if an endpoint is supported in the given PVE version.

  ## Examples

      iex> MockPveApi.Capabilities.endpoint_supported?("8.0", "/api2/json/cluster/sdn/zones")
      true
      
      iex> MockPveApi.Capabilities.endpoint_supported?("7.4", "/api2/json/cluster/sdn/zones")
      false
  """
  @spec endpoint_supported?(version(), String.t()) :: boolean()
  def endpoint_supported?(version, endpoint_path) do
    case get_endpoint_capability(endpoint_path) do
      # Endpoint doesn't require specific capability
      nil -> true
      capability -> has_capability?(version, capability)
    end
  end

  @doc """
  Gets the required capability for an endpoint, if any.
  """
  @spec get_endpoint_capability(String.t()) :: capability() | nil
  def get_endpoint_capability(endpoint_path) do
    # Try exact match first
    case Map.get(@endpoint_capabilities, endpoint_path) do
      nil ->
        # Try pattern matching for parameterized endpoints
        @endpoint_capabilities
        |> Enum.find_value(fn {pattern, capability} ->
          if matches_pattern?(endpoint_path, pattern) do
            capability
          end
        end)

      capability ->
        capability
    end
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

  # Private helper functions

  defp matches_pattern?(endpoint_path, pattern) do
    # Simple pattern matching for {param} style parameters
    pattern_regex =
      pattern
      |> String.replace("{node}", "[^/]+")
      |> String.replace("{storage}", "[^/]+")
      |> String.replace("{realm}", "[^/]+")
      |> String.replace("{vmid}", "[0-9]+")

    Regex.match?(~r/^#{pattern_regex}$/, endpoint_path)
  end
end
