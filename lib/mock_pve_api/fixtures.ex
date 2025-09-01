defmodule MockPveApi.Fixtures do
  @moduledoc """
  Version-specific response fixtures for the Mock PVE Server.

  Provides realistic response data that varies based on the configured PVE version,
  enabling comprehensive testing of version-specific features and behaviors.
  """

  alias MockPveApi.{State, Capabilities}

  @doc """
  Gets version-specific cluster resources response.

  Different PVE versions return different resource types and fields.
  """
  def cluster_resources do
    pve_version = State.get_pve_version()

    base_resources = [
      %{
        id: "node/pve-node1",
        node: "pve-node1",
        type: "node",
        status: "online",
        cpu: 0.15,
        maxcpu: 8,
        mem: 8_589_934_592,
        maxmem: 17_179_869_184,
        disk: 50_000_000_000,
        maxdisk: 100_000_000_000,
        level: "",
        uptime: 86400
      },
      %{
        id: "node/pve-node2",
        node: "pve-node2",
        type: "node",
        status: "online",
        cpu: 0.08,
        maxcpu: 4,
        mem: 4_294_967_296,
        maxmem: 8_589_934_592,
        disk: 25_000_000_000,
        maxdisk: 50_000_000_000,
        level: "",
        uptime: 172_800
      }
    ]

    # Add version-specific resource types
    case pve_version do
      "8." <> _ ->
        # PVE 8.x includes SDN resources
        sdn_resources =
          if Capabilities.has_capability?(pve_version, :sdn_tech_preview) do
            [
              %{
                id: "sdn/zones/vlan-zone",
                type: "sdn",
                status: "available",
                plugin: "vlan"
              }
            ]
          else
            []
          end

        base_resources ++ sdn_resources

      _ ->
        base_resources
    end
  end

  @doc """
  Gets version-specific node status response.
  """
  def node_status(node_name) do
    pve_version = State.get_pve_version()

    base_status = %{
      node: node_name,
      status: "online",
      cpu: 0.15,
      memory: %{
        used: 8_589_934_592,
        total: 17_179_869_184,
        free: 8_589_934_592
      },
      disk: %{
        used: 50_000_000_000,
        total: 100_000_000_000,
        free: 50_000_000_000
      },
      uptime: 86400,
      loadavg: [0.12, 0.15, 0.18],
      kversion: get_kernel_version(pve_version),
      cpuinfo: %{
        model: "Intel(R) Xeon(R) CPU E5-2680 v4",
        cores: 8,
        sockets: 1
      }
    }

    # Add version-specific fields
    case pve_version do
      "8." <> _ ->
        Map.merge(base_status, %{
          cgroup: "v2",
          pveversion: pve_version
        })

      "7." <> _ ->
        Map.merge(base_status, %{
          cgroup: "v1",
          pveversion: pve_version
        })

      _ ->
        base_status
    end
  end

  @doc """
  Gets version-specific storage content response.
  """
  def storage_content(storage_id, pve_version \\ nil) do
    pve_version = pve_version || State.get_pve_version()

    base_content =
      case storage_id do
        "local" ->
          [
            %{
              volid: "#{storage_id}:iso/ubuntu-22.04.3-live-server-amd64.iso",
              content: "iso",
              format: "iso",
              size: 1_474_560_000,
              ctime: 1_701_432_000
            },
            %{
              volid: "#{storage_id}:backup/vzdump-qemu-100-2023_12_01-12_00_00.vma.zst",
              content: "backup",
              format: "vma.zst",
              size: 2_147_483_648,
              ctime: 1_701_432_000
            }
          ]

        "local-lvm" ->
          [
            %{
              volid: "#{storage_id}:vm-100-disk-0",
              content: "images",
              format: "raw",
              size: 21_474_836_480,
              vmid: 100,
              ctime: 1_701_432_000
            }
          ]

        _ ->
          []
      end

    # Add version-specific content types or fields
    case pve_version do
      "8.2" <> _ ->
        # PVE 8.2+ has enhanced import capabilities
        if storage_id == "local" do
          import_content = [
            %{
              volid: "#{storage_id}:import/esxi-vm-disk1.vmdk",
              content: "import",
              format: "vmdk",
              size: 5_368_709_120,
              ctime: 1_701_432_000
            }
          ]

          base_content ++ import_content
        else
          base_content
        end

      _ ->
        base_content
    end
  end

  @doc """
  Gets version-specific pool response format.
  """
  def pool_response(pool_data) do
    pve_version = State.get_pve_version()

    case pve_version do
      "8." <> _ ->
        # PVE 8.x includes enhanced pool features
        Map.merge(pool_data, %{
          type: "pool",
          permissions: %{},
          resource_limits: %{}
        })

      _ ->
        pool_data
    end
  end

  @doc """
  Gets backup provider fixtures for PVE 8.2+.
  """
  def backup_providers do
    [
      %{
        id: "pbs-local",
        type: "pbs",
        server: "backup.local",
        username: "backup@pbs",
        fingerprint: "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd",
        comment: "Local Proxmox Backup Server"
      },
      %{
        id: "s3-offsite",
        type: "s3",
        bucket: "pve-backups",
        region: "us-east-1",
        comment: "AWS S3 offsite backup"
      }
    ]
  end

  @doc """
  Gets SDN zones fixture for PVE 8.0+.
  """
  def sdn_zones do
    [
      %{
        zone: "vlan-zone",
        type: "vlan",
        bridge: "vmbr0",
        pending: false,
        state: "available"
      },
      %{
        zone: "simple-zone",
        type: "simple",
        bridge: "vmbr1",
        pending: false,
        state: "available"
      }
    ]
  end

  @doc """
  Gets notification endpoints fixture for PVE 8.1+.
  """
  def notification_endpoints do
    [
      %{
        name: "mail-admins",
        type: "smtp",
        server: "mail.company.com",
        port: 587,
        username: "pve@company.com",
        comment: "Admin email notifications"
      },
      %{
        name: "slack-alerts",
        type: "gotify",
        server: "https://gotify.company.com",
        comment: "Slack webhook notifications"
      }
    ]
  end

  @doc """
  Gets version-specific task response.
  """
  def task_response(task_type, pve_version \\ nil) do
    pve_version = pve_version || State.get_pve_version()

    base_task = %{
      upid: "UPID:pve-node1:12345:#{:os.system_time(:second)}:#{task_type}:root@pam:",
      type: task_type,
      id: "root@pam",
      user: "root@pam",
      status: "running",
      starttime: :os.system_time(:second)
    }

    # Add version-specific task fields
    case pve_version do
      "8." <> _ ->
        Map.merge(base_task, %{
          worker_id: "12345",
          saved: false
        })

      _ ->
        base_task
    end
  end

  # Private helper functions

  defp get_kernel_version("7." <> _), do: "5.15.108-1-pve"
  defp get_kernel_version("8.0"), do: "6.2.16-15-pve"
  defp get_kernel_version("8.1"), do: "6.5.11-7-pve"
  defp get_kernel_version("8.2"), do: "6.8.4-2-pve"
  defp get_kernel_version("8.3"), do: "6.8.12-1-pve"
  defp get_kernel_version(_), do: "6.2.16-15-pve"
end
