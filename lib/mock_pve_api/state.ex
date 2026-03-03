# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.State do
  @moduledoc """
  State management for mock PVE resources.

  Maintains in-memory state for VMs, containers, nodes, storage, and other
  PVE resources to support realistic lifecycle testing scenarios.

  Now includes version-aware capabilities to support different PVE versions.
  """

  use GenServer
  require Logger

  alias MockPveApi.Capabilities

  @name __MODULE__

  # Default state structure
  defp initial_state do
    pve_version = Application.get_env(:mock_pve_api, :pve_version, "8.0")

    %{
      pve_version: pve_version,
      capabilities: Capabilities.get_capabilities(pve_version),
      nodes: %{
        "pve-node1" => %{
          node: "pve-node1",
          status: "online",
          cpu: 0.15,
          maxcpu: 8,
          # 8GB
          mem: 8_589_934_592,
          # 16GB
          maxmem: 17_179_869_184,
          # 50GB
          disk: 50_000_000_000,
          # 100GB
          maxdisk: 100_000_000_000,
          uptime: 86400,
          version: pve_version,
          kernel: "6.2.16-15-pve"
        },
        "pve-node2" => %{
          node: "pve-node2",
          status: "online",
          cpu: 0.08,
          maxcpu: 4,
          # 4GB
          mem: 4_294_967_296,
          # 8GB
          maxmem: 8_589_934_592,
          # 25GB
          disk: 25_000_000_000,
          # 50GB
          maxdisk: 50_000_000_000,
          uptime: 172_800,
          version: pve_version,
          kernel: "6.2.16-15-pve"
        }
      },
      vms: %{},
      containers: %{},
      storage: %{
        "local" => %{
          storage: "local",
          type: "dir",
          content: "vztmpl,backup,iso",
          path: "/var/lib/vz",
          nodes: "pve-node1,pve-node2",
          maxfiles: 0,
          enabled: 1
        },
        "local-lvm" => %{
          storage: "local-lvm",
          type: "lvmthin",
          content: "images,rootdir",
          vgname: "pve",
          thinpool: "data",
          nodes: "pve-node1,pve-node2",
          enabled: 1
        }
      },
      snapshots: %{},
      ha_resources: %{},
      ha_groups: %{},
      ha_affinity_rules: %{},
      backup_jobs: %{},
      next_backup_job_id: 1,
      cluster_options: %{
        keyboard: "en-us",
        language: "en",
        console: "default",
        email_from: "root",
        max_workers: 4,
        migration_type: "secure",
        ha: %{shutdown_policy: "conditional"}
      },
      sdn_zones: %{},
      sdn_vnets: %{},
      sdn_subnets: %{},
      sdn_controllers: %{},
      sdn_dns: %{},
      sdn_ipams: %{},
      pci_mappings: %{},
      usb_mappings: %{},
      storage_content: %{},
      node_dns: %{},
      node_network_interfaces: %{
        "pve-node1" => %{
          "eth0" => %{
            iface: "eth0",
            type: "eth",
            active: 1,
            autostart: 1,
            method: "static",
            address: "192.168.1.10",
            netmask: "255.255.255.0",
            gateway: "192.168.1.1"
          },
          "vmbr0" => %{
            iface: "vmbr0",
            type: "bridge",
            active: 1,
            autostart: 1,
            method: "static",
            address: "192.168.1.10",
            netmask: "255.255.255.0",
            gateway: "192.168.1.1",
            bridge_ports: "eth0",
            bridge_stp: "off",
            bridge_fd: 0
          }
        },
        "pve-node2" => %{
          "eth0" => %{
            iface: "eth0",
            type: "eth",
            active: 1,
            autostart: 1,
            method: "static",
            address: "192.168.1.11",
            netmask: "255.255.255.0",
            gateway: "192.168.1.1"
          },
          "vmbr0" => %{
            iface: "vmbr0",
            type: "bridge",
            active: 1,
            autostart: 1,
            method: "static",
            address: "192.168.1.11",
            netmask: "255.255.255.0",
            gateway: "192.168.1.1",
            bridge_ports: "eth0",
            bridge_stp: "off",
            bridge_fd: 0
          }
        }
      },
      node_configs: %{},
      replication_jobs: %{},
      acme_accounts: %{},
      acme_plugins: %{},
      notification_gotify: %{},
      notification_sendmail: %{},
      notification_matchers: %{},
      firewall: %{
        cluster: %{
          options: %{
            enable: 0,
            policy_in: "DROP",
            policy_out: "ACCEPT",
            log_ratelimit: "enable=1,rate=1/second,burst=5"
          },
          rules: [],
          groups: %{},
          aliases: %{},
          ipsets: %{}
        },
        nodes: %{},
        vms: %{},
        containers: %{}
      },
      pools: %{},
      users: %{
        "root@pam" => %{
          userid: "root@pam",
          comment: "Root user",
          enable: 1,
          expire: 0,
          groups: []
        }
      },
      groups: %{
        "admin" => %{
          groupid: "admin",
          comment: "System administrators"
        }
      },
      domains: %{
        "pam" => %{
          realm: "pam",
          type: "pam",
          comment: "PAM standard authentication",
          default: 1
        },
        "pve" => %{
          realm: "pve",
          type: "pve",
          comment: "Proxmox VE authentication server"
        }
      },
      cluster_config: %{
        cluster_name: "pve-cluster",
        nodes: %{
          "pve-node1" => %{
            name: "pve-node1",
            nodeid: 1,
            votes: 1,
            ring0_addr: "192.168.1.10",
            quorum_votes: 1,
            online: true
          },
          "pve-node2" => %{
            name: "pve-node2",
            nodeid: 2,
            votes: 1,
            ring0_addr: "192.168.1.11",
            quorum_votes: 1,
            online: true
          }
        },
        expected_votes: 2,
        quorum: %{
          expected_votes: 2,
          total_votes: 2,
          quorate: 1
        },
        cluster_log: []
      },
      next_vmid: 100,
      tasks: %{},
      next_upid: 1,
      backups: %{},
      tickets: %{},
      api_tokens: %{},
      permissions: %{
        "/" => %{
          "root@pam" => ["Administrator"]
        }
      },
      roles: %{
        "Administrator" => [
          "VM.Allocate",
          "VM.Audit",
          "VM.Backup",
          "VM.Clone",
          "VM.Config.CDROM",
          "VM.Config.CPU",
          "VM.Config.Cloudinit",
          "VM.Config.Disk",
          "VM.Config.HWType",
          "VM.Config.Memory",
          "VM.Config.Network",
          "VM.Config.Options",
          "VM.Migrate",
          "VM.Monitor",
          "VM.PowerMgmt",
          "VM.Snapshot",
          "VM.Snapshot.Rollback"
        ]
      },
      metrics_servers: %{}
    }
  end

  ## Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, initial_state(), name: @name)
  end

  def get_state do
    GenServer.call(@name, :get_state)
  end

  def reset do
    GenServer.call(@name, :reset)
  end

  # Node operations
  def get_nodes do
    GenServer.call(@name, :get_nodes)
  end

  def get_node(name) do
    GenServer.call(@name, {:get_node, name})
  end

  def update_node(name, updates) do
    GenServer.cast(@name, {:update_node, name, updates})
  end

  # VM operations
  def get_vms(node \\ nil) do
    GenServer.call(@name, {:get_vms, node})
  end

  def get_vm(node, vmid) do
    GenServer.call(@name, {:get_vm, node, vmid})
  end

  def create_vm(node, vmid, config) do
    GenServer.call(@name, {:create_vm, node, vmid, config})
  end

  def update_vm(node, vmid, config) do
    GenServer.call(@name, {:update_vm, node, vmid, config})
  end

  def delete_vm(node, vmid) do
    GenServer.cast(@name, {:delete_vm, node, vmid})
  end

  # Container operations
  def get_containers(node \\ nil) do
    GenServer.call(@name, {:get_containers, node})
  end

  def get_container(node, vmid) do
    GenServer.call(@name, {:get_container, node, vmid})
  end

  def create_container(node, vmid, config) do
    GenServer.call(@name, {:create_container, node, vmid, config})
  end

  def update_container(node, vmid, config) do
    GenServer.call(@name, {:update_container, node, vmid, config})
  end

  def delete_container(node, vmid) do
    GenServer.cast(@name, {:delete_container, node, vmid})
  end

  # Snapshot operations
  def list_snapshots(vmid) do
    GenServer.call(@name, {:list_snapshots, vmid})
  end

  def get_snapshot(vmid, snapname) do
    GenServer.call(@name, {:get_snapshot, vmid, snapname})
  end

  def create_snapshot(vmid, snapname, params \\ %{}) do
    GenServer.call(@name, {:create_snapshot, vmid, snapname, params})
  end

  def get_snapshot_config(vmid, snapname) do
    GenServer.call(@name, {:get_snapshot_config, vmid, snapname})
  end

  def update_snapshot_config(vmid, snapname, params) do
    GenServer.call(@name, {:update_snapshot_config, vmid, snapname, params})
  end

  def delete_snapshot(vmid, snapname) do
    GenServer.call(@name, {:delete_snapshot, vmid, snapname})
  end

  def rollback_snapshot(vmid, snapname) do
    GenServer.call(@name, {:rollback_snapshot, vmid, snapname})
  end

  # Storage operations
  def get_storage do
    GenServer.call(@name, :get_storage)
  end

  def get_storage_content(node, storage) do
    GenServer.call(@name, {:get_storage_content, node, storage})
  end

  def add_storage_content(node, storage, content) do
    GenServer.call(@name, {:add_storage_content, node, storage, content})
  end

  def get_storage_status(storage_id) do
    GenServer.call(@name, {:get_storage_status, storage_id})
  end

  # Pool operations
  def get_pools do
    GenServer.call(@name, :get_pools)
  end

  def create_pool(poolid, config) do
    GenServer.call(@name, {:create_pool, poolid, config})
  end

  def update_pool(poolid, params) do
    GenServer.call(@name, {:update_pool, poolid, params})
  end

  def delete_pool(poolid) do
    GenServer.cast(@name, {:delete_pool, poolid})
  end

  # Task operations
  def create_task(node, type, params \\ %{}) do
    GenServer.call(@name, {:create_task, node, type, params})
  end

  def get_tasks(node) do
    GenServer.call(@name, {:get_tasks, node})
  end

  def get_task(upid) do
    GenServer.call(@name, {:get_task, upid})
  end

  def update_task(upid, updates) do
    GenServer.cast(@name, {:update_task, upid, updates})
  end

  # Backup operations
  def create_backup(node, vmid, params \\ %{}) do
    GenServer.call(@name, {:create_backup, node, vmid, params})
  end

  def list_backups(node, storage) do
    GenServer.call(@name, {:list_backups, node, storage})
  end

  def restore_backup(node, vmid, backup_file, params \\ %{}) do
    GenServer.call(@name, {:restore_backup, node, vmid, backup_file, params})
  end

  # Migrate operations
  def migrate_vm(node, vmid, target_node, params \\ %{}) do
    GenServer.call(@name, {:migrate_vm, node, vmid, target_node, params})
  end

  def migrate_container(node, vmid, target_node, params \\ %{}) do
    GenServer.call(@name, {:migrate_container, node, vmid, target_node, params})
  end

  # Authentication operations
  def create_ticket(username, password, params \\ %{}) do
    GenServer.call(@name, {:create_ticket, username, password, params})
  end

  def validate_ticket(ticket) do
    GenServer.call(@name, {:validate_ticket, ticket})
  end

  def create_api_token(username, tokenid, params \\ %{}) do
    GenServer.call(@name, {:create_api_token, username, tokenid, params})
  end

  # Permission operations
  def get_permissions(userid) do
    GenServer.call(@name, {:get_permissions, userid})
  end

  def set_permissions(path, userid, roleid) do
    GenServer.call(@name, {:set_permissions, path, userid, roleid})
  end

  # User management operations
  def create_user(userid, params) do
    GenServer.call(@name, {:create_user, userid, params})
  end

  def update_user(userid, params) do
    GenServer.call(@name, {:update_user, userid, params})
  end

  def delete_user(userid) do
    GenServer.call(@name, {:delete_user, userid})
  end

  # Group management operations
  def create_group(groupid, params) do
    GenServer.call(@name, {:create_group, groupid, params})
  end

  def update_group(groupid, params) do
    GenServer.call(@name, {:update_group, groupid, params})
  end

  def delete_group(groupid) do
    GenServer.call(@name, {:delete_group, groupid})
  end

  # API Token management operations
  def delete_api_token(tokenid) do
    GenServer.call(@name, {:delete_api_token, tokenid})
  end

  def update_api_token(tokenid, params) do
    GenServer.call(@name, {:update_api_token, tokenid, params})
  end

  # Cluster management operations
  def get_cluster_status do
    GenServer.call(@name, :get_cluster_status)
  end

  def join_cluster(hostname, nodeid, votes) do
    GenServer.call(@name, {:join_cluster, hostname, nodeid, votes})
  end

  def get_cluster_config do
    GenServer.call(@name, :get_cluster_config)
  end

  def update_cluster_config(params) do
    GenServer.call(@name, {:update_cluster_config, params})
  end

  def get_cluster_nodes_config do
    GenServer.call(@name, :get_cluster_nodes_config)
  end

  def remove_cluster_node(node_name) do
    GenServer.call(@name, {:remove_cluster_node, node_name})
  end

  def get_next_vmid do
    GenServer.call(@name, :get_next_vmid)
  end

  # HA resource operations
  def list_ha_resources do
    GenServer.call(@name, :list_ha_resources)
  end

  def get_ha_resource(sid) do
    GenServer.call(@name, {:get_ha_resource, sid})
  end

  def create_ha_resource(sid, params \\ %{}) do
    GenServer.call(@name, {:create_ha_resource, sid, params})
  end

  def update_ha_resource(sid, params) do
    GenServer.call(@name, {:update_ha_resource, sid, params})
  end

  def delete_ha_resource(sid) do
    GenServer.call(@name, {:delete_ha_resource, sid})
  end

  # HA group operations
  def list_ha_groups do
    GenServer.call(@name, :list_ha_groups)
  end

  def get_ha_group(group) do
    GenServer.call(@name, {:get_ha_group, group})
  end

  def create_ha_group(group, params \\ %{}) do
    GenServer.call(@name, {:create_ha_group, group, params})
  end

  def update_ha_group(group, params) do
    GenServer.call(@name, {:update_ha_group, group, params})
  end

  def delete_ha_group(group) do
    GenServer.call(@name, {:delete_ha_group, group})
  end

  # HA affinity rule operations
  def list_ha_affinity_rules do
    GenServer.call(@name, :list_ha_affinity_rules)
  end

  def get_ha_affinity_rule(rule) do
    GenServer.call(@name, {:get_ha_affinity_rule, rule})
  end

  def create_ha_affinity_rule(rule, params \\ %{}) do
    GenServer.call(@name, {:create_ha_affinity_rule, rule, params})
  end

  def update_ha_affinity_rule(rule, params) do
    GenServer.call(@name, {:update_ha_affinity_rule, rule, params})
  end

  def delete_ha_affinity_rule(rule) do
    GenServer.call(@name, {:delete_ha_affinity_rule, rule})
  end

  # HA status
  def get_ha_status do
    GenServer.call(@name, :get_ha_status)
  end

  # Backup job operations
  def list_backup_jobs do
    GenServer.call(@name, :list_backup_jobs)
  end

  def get_backup_job(id) do
    GenServer.call(@name, {:get_backup_job, id})
  end

  def create_backup_job(params \\ %{}) do
    GenServer.call(@name, {:create_backup_job, params})
  end

  def update_backup_job(id, params) do
    GenServer.call(@name, {:update_backup_job, id, params})
  end

  def delete_backup_job(id) do
    GenServer.call(@name, {:delete_backup_job, id})
  end

  def get_backup_job_volumes(id) do
    GenServer.call(@name, {:get_backup_job_volumes, id})
  end

  def get_not_backed_up do
    GenServer.call(@name, :get_not_backed_up)
  end

  # Cluster options
  def get_cluster_options do
    GenServer.call(@name, :get_cluster_options)
  end

  def update_cluster_options(params) do
    GenServer.call(@name, {:update_cluster_options, params})
  end

  # Domain CRUD operations
  def get_domain(realm) do
    GenServer.call(@name, {:get_domain, realm})
  end

  def create_domain(realm, params \\ %{}) do
    GenServer.call(@name, {:create_domain, realm, params})
  end

  def update_domain(realm, params) do
    GenServer.call(@name, {:update_domain, realm, params})
  end

  def delete_domain(realm) do
    GenServer.call(@name, {:delete_domain, realm})
  end

  # Role CRUD operations
  def get_role(roleid) do
    GenServer.call(@name, {:get_role, roleid})
  end

  def create_role(roleid, privs) do
    GenServer.call(@name, {:create_role, roleid, privs})
  end

  def update_role(roleid, privs) do
    GenServer.call(@name, {:update_role, roleid, privs})
  end

  def delete_role(roleid) do
    GenServer.call(@name, {:delete_role, roleid})
  end

  # Password change
  def change_password(userid, _password) do
    GenServer.call(@name, {:change_password, userid})
  end

  # ACL listing
  def get_acl do
    GenServer.call(@name, :get_acl)
  end

  # SDN zone operations
  def list_sdn_zones do
    GenServer.call(@name, :list_sdn_zones)
  end

  def get_sdn_zone(zone) do
    GenServer.call(@name, {:get_sdn_zone, zone})
  end

  def create_sdn_zone(zone, params \\ %{}) do
    GenServer.call(@name, {:create_sdn_zone, zone, params})
  end

  def update_sdn_zone(zone, params) do
    GenServer.call(@name, {:update_sdn_zone, zone, params})
  end

  def delete_sdn_zone(zone) do
    GenServer.call(@name, {:delete_sdn_zone, zone})
  end

  # SDN vnet operations
  def list_sdn_vnets do
    GenServer.call(@name, :list_sdn_vnets)
  end

  def get_sdn_vnet(vnet) do
    GenServer.call(@name, {:get_sdn_vnet, vnet})
  end

  def create_sdn_vnet(vnet, params \\ %{}) do
    GenServer.call(@name, {:create_sdn_vnet, vnet, params})
  end

  def update_sdn_vnet(vnet, params) do
    GenServer.call(@name, {:update_sdn_vnet, vnet, params})
  end

  def delete_sdn_vnet(vnet) do
    GenServer.call(@name, {:delete_sdn_vnet, vnet})
  end

  # SDN subnet operations
  def list_sdn_subnets(vnet) do
    GenServer.call(@name, {:list_sdn_subnets, vnet})
  end

  def get_sdn_subnet(vnet, subnet) do
    GenServer.call(@name, {:get_sdn_subnet, vnet, subnet})
  end

  def create_sdn_subnet(vnet, subnet, params \\ %{}) do
    GenServer.call(@name, {:create_sdn_subnet, vnet, subnet, params})
  end

  def update_sdn_subnet(vnet, subnet, params) do
    GenServer.call(@name, {:update_sdn_subnet, vnet, subnet, params})
  end

  def delete_sdn_subnet(vnet, subnet) do
    GenServer.call(@name, {:delete_sdn_subnet, vnet, subnet})
  end

  # SDN controller operations
  def list_sdn_controllers do
    GenServer.call(@name, :list_sdn_controllers)
  end

  def get_sdn_controller(controller) do
    GenServer.call(@name, {:get_sdn_controller, controller})
  end

  def create_sdn_controller(controller, params \\ %{}) do
    GenServer.call(@name, {:create_sdn_controller, controller, params})
  end

  def update_sdn_controller(controller, params) do
    GenServer.call(@name, {:update_sdn_controller, controller, params})
  end

  def delete_sdn_controller(controller) do
    GenServer.call(@name, {:delete_sdn_controller, controller})
  end

  # SDN DNS CRUD operations
  def list_sdn_dns do
    GenServer.call(@name, :list_sdn_dns)
  end

  def get_sdn_dns(dns) do
    GenServer.call(@name, {:get_sdn_dns, dns})
  end

  def create_sdn_dns(dns, params \\ %{}) do
    GenServer.call(@name, {:create_sdn_dns, dns, params})
  end

  def update_sdn_dns(dns, params) do
    GenServer.call(@name, {:update_sdn_dns, dns, params})
  end

  def delete_sdn_dns(dns) do
    GenServer.call(@name, {:delete_sdn_dns, dns})
  end

  # SDN IPAM CRUD operations
  def list_sdn_ipams do
    GenServer.call(@name, :list_sdn_ipams)
  end

  def get_sdn_ipam(ipam) do
    GenServer.call(@name, {:get_sdn_ipam, ipam})
  end

  def create_sdn_ipam(ipam, params \\ %{}) do
    GenServer.call(@name, {:create_sdn_ipam, ipam, params})
  end

  def update_sdn_ipam(ipam, params) do
    GenServer.call(@name, {:update_sdn_ipam, ipam, params})
  end

  def delete_sdn_ipam(ipam) do
    GenServer.call(@name, {:delete_sdn_ipam, ipam})
  end

  # PCI mapping CRUD operations
  def list_pci_mappings, do: GenServer.call(@name, :list_pci_mappings)
  def get_pci_mapping(id), do: GenServer.call(@name, {:get_pci_mapping, id})

  def create_pci_mapping(id, params \\ %{}),
    do: GenServer.call(@name, {:create_pci_mapping, id, params})

  def update_pci_mapping(id, params), do: GenServer.call(@name, {:update_pci_mapping, id, params})
  def delete_pci_mapping(id), do: GenServer.call(@name, {:delete_pci_mapping, id})

  # USB mapping CRUD operations
  def list_usb_mappings, do: GenServer.call(@name, :list_usb_mappings)
  def get_usb_mapping(id), do: GenServer.call(@name, {:get_usb_mapping, id})

  def create_usb_mapping(id, params \\ %{}),
    do: GenServer.call(@name, {:create_usb_mapping, id, params})

  def update_usb_mapping(id, params), do: GenServer.call(@name, {:update_usb_mapping, id, params})
  def delete_usb_mapping(id), do: GenServer.call(@name, {:delete_usb_mapping, id})

  # Storage CRUD operations
  def get_storage_by_id(storage_id) do
    GenServer.call(@name, {:get_storage_by_id, storage_id})
  end

  def create_storage(storage_id, params) do
    GenServer.call(@name, {:create_storage, storage_id, params})
  end

  def update_storage(storage_id, params) do
    GenServer.call(@name, {:update_storage, storage_id, params})
  end

  def delete_storage(storage_id) do
    GenServer.call(@name, {:delete_storage, storage_id})
  end

  # Storage volume operations
  def get_storage_volume(node, storage, volume) do
    GenServer.call(@name, {:get_storage_volume, node, storage, volume})
  end

  def delete_storage_volume(node, storage, volume) do
    GenServer.call(@name, {:delete_storage_volume, node, storage, volume})
  end

  # Node DNS operations
  def get_node_dns(node) do
    GenServer.call(@name, {:get_node_dns, node})
  end

  def update_node_dns(node, params) do
    GenServer.call(@name, {:update_node_dns, node, params})
  end

  # Node network interface operations
  def get_node_network_iface(node, iface) do
    GenServer.call(@name, {:get_node_network_iface, node, iface})
  end

  def update_node_network_iface(node, iface, params) do
    GenServer.call(@name, {:update_node_network_iface, node, iface, params})
  end

  def delete_node_network_iface(node, iface) do
    GenServer.call(@name, {:delete_node_network_iface, node, iface})
  end

  # Node config operations
  def get_node_config(node) do
    GenServer.call(@name, {:get_node_config, node})
  end

  def update_node_config(node, params) do
    GenServer.call(@name, {:update_node_config, node, params})
  end

  # Task delete
  def delete_task(upid) do
    GenServer.call(@name, {:delete_task, upid})
  end

  # VM/Container resize
  def resize_vm_disk(node, vmid, disk, size) do
    GenServer.call(@name, {:resize_vm_disk, node, vmid, disk, size})
  end

  def resize_container_disk(node, vmid, disk, size) do
    GenServer.call(@name, {:resize_container_disk, node, vmid, disk, size})
  end

  # Replication operations
  def list_replication_jobs do
    GenServer.call(@name, :list_replication_jobs)
  end

  def create_replication_job(id, params) do
    GenServer.call(@name, {:create_replication_job, id, params})
  end

  def get_replication_job(id) do
    GenServer.call(@name, {:get_replication_job, id})
  end

  def update_replication_job(id, params) do
    GenServer.call(@name, {:update_replication_job, id, params})
  end

  def delete_replication_job(id) do
    GenServer.call(@name, {:delete_replication_job, id})
  end

  # ACME account operations
  def list_acme_accounts do
    GenServer.call(@name, :list_acme_accounts)
  end

  def get_acme_account(name) do
    GenServer.call(@name, {:get_acme_account, name})
  end

  def create_acme_account(name, params \\ %{}) do
    GenServer.call(@name, {:create_acme_account, name, params})
  end

  def update_acme_account(name, params) do
    GenServer.call(@name, {:update_acme_account, name, params})
  end

  def delete_acme_account(name) do
    GenServer.call(@name, {:delete_acme_account, name})
  end

  # ACME plugin operations
  def list_acme_plugins do
    GenServer.call(@name, :list_acme_plugins)
  end

  def get_acme_plugin(id) do
    GenServer.call(@name, {:get_acme_plugin, id})
  end

  def create_acme_plugin(id, params \\ %{}) do
    GenServer.call(@name, {:create_acme_plugin, id, params})
  end

  def update_acme_plugin(id, params) do
    GenServer.call(@name, {:update_acme_plugin, id, params})
  end

  def delete_acme_plugin(id) do
    GenServer.call(@name, {:delete_acme_plugin, id})
  end

  # Notification operations
  def list_notification_endpoints(type) do
    GenServer.call(@name, {:list_notification_endpoints, type})
  end

  def get_notification_endpoint(type, name) do
    GenServer.call(@name, {:get_notification_endpoint, type, name})
  end

  def create_notification_endpoint(type, name, params \\ %{}) do
    GenServer.call(@name, {:create_notification_endpoint, type, name, params})
  end

  def update_notification_endpoint(type, name, params) do
    GenServer.call(@name, {:update_notification_endpoint, type, name, params})
  end

  def delete_notification_endpoint(type, name) do
    GenServer.call(@name, {:delete_notification_endpoint, type, name})
  end

  def list_notification_matchers do
    GenServer.call(@name, :list_notification_matchers)
  end

  def get_notification_matcher(name) do
    GenServer.call(@name, {:get_notification_matcher, name})
  end

  def create_notification_matcher(name, params \\ %{}) do
    GenServer.call(@name, {:create_notification_matcher, name, params})
  end

  def update_notification_matcher(name, params) do
    GenServer.call(@name, {:update_notification_matcher, name, params})
  end

  def delete_notification_matcher(name) do
    GenServer.call(@name, {:delete_notification_matcher, name})
  end

  # Firewall operations
  def get_firewall(scope) do
    GenServer.call(@name, {:get_firewall, scope})
  end

  def update_firewall(scope, updates) do
    GenServer.call(@name, {:update_firewall, scope, updates})
  end

  # Metrics server operations
  def get_metrics_servers do
    GenServer.call(@name, :get_metrics_servers)
  end

  def get_metrics_server(id) do
    GenServer.call(@name, {:get_metrics_server, id})
  end

  def create_metrics_server(id, params) do
    GenServer.call(@name, {:create_metrics_server, id, params})
  end

  def update_metrics_server(id, params) do
    GenServer.call(@name, {:update_metrics_server, id, params})
  end

  def delete_metrics_server(id) do
    GenServer.call(@name, {:delete_metrics_server, id})
  end

  # Version and capability operations
  def get_pve_version do
    GenServer.call(@name, :get_pve_version)
  end

  def get_capabilities do
    GenServer.call(@name, :get_capabilities)
  end

  def has_capability?(capability) do
    GenServer.call(@name, {:has_capability, capability})
  end

  def endpoint_supported?(endpoint_path) do
    GenServer.call(@name, {:endpoint_supported, endpoint_path})
  end

  ## Server Callbacks

  @impl true
  def init(state) do
    Logger.info("Mock PVE Server state initialized")
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_nodes, _from, state) do
    nodes = Map.values(state.nodes)
    {:reply, nodes, state}
  end

  def handle_call({:get_node, name}, _from, state) do
    node = Map.get(state.nodes, name)
    {:reply, node, state}
  end

  def handle_call({:get_vms, node}, _from, state) do
    vms =
      case node do
        nil ->
          Map.values(state.vms)

        node ->
          state.vms
          |> Enum.filter(fn {_vmid, vm} -> vm.node == node end)
          |> Enum.map(&elem(&1, 1))
      end

    {:reply, vms, state}
  end

  def handle_call({:get_vm, node, vmid}, _from, state) do
    vm = Map.get(state.vms, vmid)
    result = if vm && vm.node == node, do: vm, else: nil
    {:reply, result, state}
  end

  def handle_call({:create_vm, node, vmid, config}, _from, state) do
    if Map.has_key?(state.vms, vmid) do
      {:reply, {:error, "VM #{vmid} already exists"}, state}
    else
      vm =
        Map.merge(
          %{
            vmid: vmid,
            node: node,
            status: "stopped",
            name: Map.get(config, :name, "vm-#{vmid}"),
            memory: Map.get(config, :memory, 2048),
            cores: Map.get(config, :cores, 2),
            sockets: Map.get(config, :sockets, 1),
            ostype: Map.get(config, :ostype, "l26"),
            bootdisk: Map.get(config, :bootdisk, "scsi0")
          },
          config
        )

      new_vms = Map.put(state.vms, vmid, vm)
      new_state = %{state | vms: new_vms}

      {:reply, {:ok, vm}, new_state}
    end
  end

  def handle_call({:update_vm, node, vmid, config}, _from, state) do
    case Map.get(state.vms, vmid) do
      nil ->
        {:reply, {:error, "VM #{vmid} not found"}, state}

      vm when vm.node == node ->
        updated_vm = Map.merge(vm, config)
        new_vms = Map.put(state.vms, vmid, updated_vm)
        new_state = %{state | vms: new_vms}
        {:reply, {:ok, updated_vm}, new_state}

      _ ->
        {:reply, {:error, "VM #{vmid} not found on node #{node}"}, state}
    end
  end

  def handle_call({:get_containers, node}, _from, state) do
    containers =
      case node do
        nil ->
          Map.values(state.containers)

        node ->
          state.containers
          |> Enum.filter(fn {_vmid, ct} -> ct.node == node end)
          |> Enum.map(&elem(&1, 1))
      end

    {:reply, containers, state}
  end

  def handle_call({:get_container, node, vmid}, _from, state) do
    container = Map.get(state.containers, vmid)
    result = if container && container.node == node, do: container, else: nil
    {:reply, result, state}
  end

  def handle_call({:create_container, node, vmid, config}, _from, state) do
    if Map.has_key?(state.containers, vmid) do
      {:reply, {:error, "Container #{vmid} already exists"}, state}
    else
      container =
        Map.merge(
          %{
            vmid: vmid,
            node: node,
            type: "lxc",
            status: "stopped",
            hostname: Map.get(config, :hostname, "ct-#{vmid}"),
            memory: Map.get(config, :memory, 1024),
            swap: Map.get(config, :swap, 512),
            cores: Map.get(config, :cores, 1),
            ostemplate:
              Map.get(
                config,
                :ostemplate,
                "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
              ),
            rootfs: Map.get(config, :rootfs, "local-lvm:8")
          },
          config
        )

      new_containers = Map.put(state.containers, vmid, container)
      new_state = %{state | containers: new_containers}

      {:reply, {:ok, container}, new_state}
    end
  end

  def handle_call({:update_container, node, vmid, config}, _from, state) do
    case Map.get(state.containers, vmid) do
      nil ->
        {:reply, {:error, "Container #{vmid} not found"}, state}

      container when container.node == node ->
        updated_container = Map.merge(container, config)
        new_containers = Map.put(state.containers, vmid, updated_container)
        new_state = %{state | containers: new_containers}
        {:reply, {:ok, updated_container}, new_state}

      _ ->
        {:reply, {:error, "Container #{vmid} not found on node #{node}"}, state}
    end
  end

  # Snapshot callbacks
  def handle_call({:list_snapshots, vmid}, _from, state) do
    snapshots =
      state.snapshots
      |> Enum.filter(fn {{vid, _snapname}, _snap} -> vid == vmid end)
      |> Enum.map(fn {_key, snap} -> snap end)

    # PVE always includes a "current" pseudo-snapshot
    current = %{name: "current", description: "You are here!", snaptime: 0, parent: nil}
    {:reply, [current | snapshots], state}
  end

  def handle_call({:get_snapshot, vmid, snapname}, _from, state) do
    snapshot = Map.get(state.snapshots, {vmid, snapname})
    {:reply, snapshot, state}
  end

  def handle_call({:create_snapshot, vmid, snapname, params}, _from, state) do
    key = {vmid, snapname}

    if Map.has_key?(state.snapshots, key) do
      {:reply, {:error, "Snapshot '#{snapname}' already exists"}, state}
    else
      # Find parent (most recent snapshot or nil)
      parent =
        state.snapshots
        |> Enum.filter(fn {{vid, _}, _} -> vid == vmid end)
        |> Enum.sort_by(fn {_, snap} -> snap.snap_order end, :desc)
        |> case do
          [{_, latest} | _] -> latest.name
          [] -> nil
        end

      snapshot = %{
        name: snapname,
        description: Map.get(params, :description, Map.get(params, "description", "")),
        snaptime: System.system_time(:second),
        # Monotonic counter for reliable ordering in tests
        snap_order: System.monotonic_time(),
        vmstate: Map.get(params, :vmstate, Map.get(params, "vmstate", 0)),
        parent: parent
      }

      new_snapshots = Map.put(state.snapshots, key, snapshot)
      {:reply, {:ok, snapshot}, %{state | snapshots: new_snapshots}}
    end
  end

  def handle_call({:get_snapshot_config, vmid, snapname}, _from, state) do
    case Map.get(state.snapshots, {vmid, snapname}) do
      nil -> {:reply, {:error, "Snapshot '#{snapname}' not found"}, state}
      snapshot -> {:reply, {:ok, snapshot}, state}
    end
  end

  def handle_call({:update_snapshot_config, vmid, snapname, params}, _from, state) do
    key = {vmid, snapname}

    case Map.get(state.snapshots, key) do
      nil ->
        {:reply, {:error, "Snapshot '#{snapname}' not found"}, state}

      snapshot ->
        description =
          Map.get(params, :description, Map.get(params, "description", snapshot.description))

        updated = %{snapshot | description: description}
        new_snapshots = Map.put(state.snapshots, key, updated)
        {:reply, {:ok, updated}, %{state | snapshots: new_snapshots}}
    end
  end

  def handle_call({:delete_snapshot, vmid, snapname}, _from, state) do
    key = {vmid, snapname}

    case Map.get(state.snapshots, key) do
      nil ->
        {:reply, {:error, "Snapshot '#{snapname}' not found"}, state}

      deleted_snap ->
        # Update children's parent pointers
        new_snapshots =
          state.snapshots
          |> Map.delete(key)
          |> Enum.map(fn {k, snap} ->
            {vid, _sn} = k

            if vid == vmid && snap.parent == snapname do
              {k, %{snap | parent: deleted_snap.parent}}
            else
              {k, snap}
            end
          end)
          |> Map.new()

        {:reply, :ok, %{state | snapshots: new_snapshots}}
    end
  end

  def handle_call({:rollback_snapshot, vmid, snapname}, _from, state) do
    key = {vmid, snapname}

    case Map.get(state.snapshots, key) do
      nil ->
        {:reply, {:error, "Snapshot '#{snapname}' not found"}, state}

      target_snap ->
        # Remove all snapshots newer than the target (using monotonic order)
        new_snapshots =
          state.snapshots
          |> Enum.reject(fn {{vid, _sn}, snap} ->
            vid == vmid && snap.snap_order > target_snap.snap_order
          end)
          |> Map.new()

        {:reply, :ok, %{state | snapshots: new_snapshots}}
    end
  end

  def handle_call(:get_storage, _from, state) do
    storage = Map.values(state.storage)
    {:reply, storage, state}
  end

  def handle_call({:get_storage_content, _node, storage_id}, _from, state) do
    storage = Map.get(state.storage, storage_id)

    if storage do
      # Generate some sample content based on storage type
      content =
        case storage.type do
          "dir" ->
            [
              %{
                volid: "#{storage_id}:iso/ubuntu-22.04.3-live-server-amd64.iso",
                content: "iso",
                format: "iso",
                size: 1_474_560_000
              },
              %{
                volid: "#{storage_id}:backup/vzdump-qemu-100-2023_12_01-12_00_00.vma.zst",
                content: "backup",
                format: "vma.zst",
                size: 2_147_483_648
              }
            ]

          "lvmthin" ->
            [
              %{
                volid: "#{storage_id}:vm-100-disk-0",
                content: "images",
                format: "raw",
                size: 21_474_836_480,
                vmid: 100
              }
            ]

          _ ->
            []
        end

      {:reply, content, state}
    else
      {:reply, [], state}
    end
  end

  def handle_call({:add_storage_content, _node, storage_id, content}, _from, state) do
    storage = Map.get(state.storage, storage_id)

    if storage do
      # In a real implementation, we'd maintain a storage content registry
      # For now, we'll just return success with the created content
      {:reply, {:ok, content}, state}
    else
      {:reply, {:error, "Storage '#{storage_id}' not found"}, state}
    end
  end

  def handle_call(:get_pools, _from, state) do
    pools = Map.values(state.pools)
    {:reply, pools, state}
  end

  def handle_call({:create_pool, poolid, config}, _from, state) do
    if Map.has_key?(state.pools, poolid) do
      {:reply, {:error, "Pool #{poolid} already exists"}, state}
    else
      pool =
        Map.merge(
          %{
            poolid: poolid,
            comment: Map.get(config, :comment, ""),
            members: []
          },
          config
        )

      new_pools = Map.put(state.pools, poolid, pool)
      new_state = %{state | pools: new_pools}

      {:reply, {:ok, pool}, new_state}
    end
  end

  def handle_call({:update_pool, poolid, params}, _from, state) do
    case Map.get(state.pools, poolid) do
      nil ->
        {:reply, {:error, "Pool '#{poolid}' not found"}, state}

      existing_pool ->
        updated_pool =
          Map.merge(existing_pool, %{
            comment: Map.get(params, "comment", existing_pool.comment)
          })

        new_pools = Map.put(state.pools, poolid, updated_pool)
        new_state = %{state | pools: new_pools}

        {:reply, {:ok, updated_pool}, new_state}
    end
  end

  def handle_call({:create_task, node, type, params}, _from, state) do
    upid = "UPID:#{node}:#{state.next_upid}:#{:os.system_time(:second)}:#{type}:root@pam:"

    task =
      Map.merge(
        %{
          upid: upid,
          node: node,
          type: type,
          id: "root@pam",
          user: "root@pam",
          status: "OK",
          exitstatus: "OK",
          starttime: :os.system_time(:second),
          endtime: :os.system_time(:second) + 1,
          pstart: state.next_upid
        },
        params
      )

    new_tasks = Map.put(state.tasks, upid, task)
    new_state = %{state | tasks: new_tasks, next_upid: state.next_upid + 1}

    {:reply, {:ok, upid}, new_state}
  end

  def handle_call({:get_tasks, node}, _from, state) do
    tasks =
      state.tasks
      |> Enum.filter(fn {_upid, task} -> task.node == node end)
      |> Enum.map(&elem(&1, 1))

    {:reply, tasks, state}
  end

  def handle_call(:get_next_vmid, _from, state) do
    vmid = state.next_vmid
    new_state = %{state | next_vmid: vmid + 1}
    {:reply, vmid, new_state}
  end

  def handle_call(:get_pve_version, _from, state) do
    {:reply, state.pve_version, state}
  end

  def handle_call(:get_capabilities, _from, state) do
    {:reply, state.capabilities, state}
  end

  def handle_call({:has_capability, capability}, _from, state) do
    has_capability = capability in state.capabilities
    {:reply, has_capability, state}
  end

  def handle_call({:endpoint_supported, endpoint_path}, _from, state) do
    supported = Capabilities.endpoint_supported?(state.pve_version, endpoint_path)
    {:reply, supported, state}
  end

  def handle_call({:get_task, upid}, _from, state) do
    task = Map.get(state.tasks, upid)
    {:reply, task, state}
  end

  def handle_call({:create_backup, node, vmid, params}, _from, state) do
    backup_file =
      "vzdump-#{if vmid < 1000, do: "qemu", else: "lxc"}-#{vmid}-#{Date.utc_today()}-12_00_00.vma.zst"

    storage = Map.get(params, :storage, "local")

    backup = %{
      node: node,
      vmid: vmid,
      filename: backup_file,
      storage: storage,
      size: :rand.uniform(5_000_000_000) + 1_000_000_000,
      ctime: :os.system_time(:second),
      format: "vma.zst"
    }

    # Create backup entry
    backup_key = "#{storage}:backup/#{backup_file}"
    new_backups = Map.put(state.backups, backup_key, backup)

    # Create task for backup operation
    {:reply, {:ok, upid}, new_state} =
      handle_call({:create_task, node, "vzdump", %{vmid: vmid}}, nil, %{
        state
        | backups: new_backups
      })

    {:reply, {:ok, upid}, new_state}
  end

  def handle_call({:list_backups, node, storage}, _from, state) do
    backups =
      state.backups
      |> Enum.filter(fn {_key, backup} -> backup.node == node and backup.storage == storage end)
      |> Enum.map(&elem(&1, 1))

    {:reply, backups, state}
  end

  def handle_call({:restore_backup, node, vmid, backup_file, _params}, _from, state) do
    # Check if backup exists
    case Enum.find(state.backups, fn {_key, backup} ->
           backup.filename == backup_file and backup.node == node
         end) do
      nil ->
        {:reply, {:error, "Backup file not found"}, state}

      {_key, _backup} ->
        # Create task for restore operation
        {:reply, {:ok, upid}, new_state} =
          handle_call(
            {:create_task, node, "qmrestore", %{vmid: vmid, archive: backup_file}},
            nil,
            state
          )

        {:reply, {:ok, upid}, new_state}
    end
  end

  def handle_call({:migrate_vm, node, vmid, target_node, _params}, _from, state) do
    case Map.get(state.vms, vmid) do
      nil ->
        {:reply, {:error, "VM #{vmid} not found"}, state}

      vm when vm.node != node ->
        {:reply, {:error, "VM #{vmid} not on node #{node}"}, state}

      vm ->
        # Update VM to new node
        updated_vm = %{vm | node: target_node}
        new_vms = Map.put(state.vms, vmid, updated_vm)

        # Create migration task
        {:reply, {:ok, upid}, new_state} =
          handle_call(
            {:create_task, node, "qmigrate", %{vmid: vmid, target: target_node}},
            nil,
            %{state | vms: new_vms}
          )

        {:reply, {:ok, upid}, new_state}
    end
  end

  def handle_call({:migrate_container, node, vmid, target_node, _params}, _from, state) do
    case Map.get(state.containers, vmid) do
      nil ->
        {:reply, {:error, "Container #{vmid} not found"}, state}

      container when container.node != node ->
        {:reply, {:error, "Container #{vmid} not on node #{node}"}, state}

      container ->
        # Update container to new node
        updated_container = %{container | node: target_node}
        new_containers = Map.put(state.containers, vmid, updated_container)

        # Create migration task
        {:reply, {:ok, upid}, new_state} =
          handle_call(
            {:create_task, node, "pctmigrate", %{vmid: vmid, target: target_node}},
            nil,
            %{state | containers: new_containers}
          )

        {:reply, {:ok, upid}, new_state}
    end
  end

  def handle_call({:create_ticket, username, _password, _params}, _from, state) do
    # Mock authentication - in real PVE this would validate against PAM/LDAP/etc
    case Map.get(state.users, username) do
      nil ->
        {:reply, {:error, "Authentication failed"}, state}

      _user ->
        ticket = :crypto.strong_rand_bytes(32) |> Base.encode64()
        csrf_token = :crypto.strong_rand_bytes(16) |> Base.encode64()

        ticket_data = %{
          username: username,
          ticket: ticket,
          csrf_token: csrf_token,
          created_at: :os.system_time(:second),
          # 2 hours
          expires_at: :os.system_time(:second) + 7200
        }

        new_tickets = Map.put(state.tickets, ticket, ticket_data)

        response = %{
          username: username,
          ticket: ticket,
          CSRFPreventionToken: csrf_token
        }

        {:reply, {:ok, response}, %{state | tickets: new_tickets}}
    end
  end

  def handle_call({:validate_ticket, ticket}, _from, state) do
    case Map.get(state.tickets, ticket) do
      nil ->
        {:reply, {:error, "Invalid ticket"}, state}

      ticket_data ->
        if ticket_data.expires_at > :os.system_time(:second) do
          {:reply, {:ok, ticket_data}, state}
        else
          # Ticket expired, remove it
          new_tickets = Map.delete(state.tickets, ticket)
          {:reply, {:error, "Ticket expired"}, %{state | tickets: new_tickets}}
        end
    end
  end

  def handle_call({:create_api_token, username, tokenid, params}, _from, state) do
    case Map.get(state.users, username) do
      nil ->
        {:reply, {:error, "User not found"}, state}

      _user ->
        token_value = :crypto.strong_rand_bytes(32) |> Base.encode64()
        full_tokenid = "#{username}!#{tokenid}"

        token_data = %{
          tokenid: full_tokenid,
          token: token_value,
          privsep: Map.get(params, :privsep, 1),
          comment: Map.get(params, :comment, ""),
          expire: Map.get(params, :expire, 0),
          created_at: :os.system_time(:second)
        }

        new_tokens = Map.put(state.api_tokens, full_tokenid, token_data)

        response = %{
          tokenid: full_tokenid,
          value: "#{full_tokenid}=#{token_value}"
        }

        {:reply, {:ok, response}, %{state | api_tokens: new_tokens}}
    end
  end

  def handle_call({:get_permissions, userid}, _from, state) do
    permissions =
      state.permissions
      |> Enum.filter(fn {_path, users} -> Map.has_key?(users, userid) end)
      |> Enum.map(fn {path, users} ->
        roles = Map.get(users, userid, [])
        privileges = Enum.flat_map(roles, fn role -> Map.get(state.roles, role, []) end)
        %{path: path, roles: roles, privileges: privileges}
      end)

    {:reply, permissions, state}
  end

  def handle_call({:set_permissions, path, userid, roleid}, _from, state) do
    current_path_perms = Map.get(state.permissions, path, %{})
    current_user_roles = Map.get(current_path_perms, userid, [])
    updated_roles = [roleid | current_user_roles] |> Enum.uniq()

    new_path_perms = Map.put(current_path_perms, userid, updated_roles)
    new_permissions = Map.put(state.permissions, path, new_path_perms)

    {:reply, :ok, %{state | permissions: new_permissions}}
  end

  # User management callbacks
  def handle_call({:create_user, userid, params}, _from, state) do
    if Map.has_key?(state.users, userid) do
      {:reply, {:error, "User #{userid} already exists"}, state}
    else
      user =
        Map.merge(
          %{
            userid: userid,
            comment: "",
            enable: 1,
            expire: 0,
            groups: []
          },
          params
        )

      new_users = Map.put(state.users, userid, user)
      new_state = %{state | users: new_users}

      {:reply, {:ok, user}, new_state}
    end
  end

  def handle_call({:update_user, userid, params}, _from, state) do
    case Map.get(state.users, userid) do
      nil ->
        {:reply, {:error, "User #{userid} not found"}, state}

      user ->
        updated_user = Map.merge(user, params)
        new_users = Map.put(state.users, userid, updated_user)
        new_state = %{state | users: new_users}
        {:reply, {:ok, updated_user}, new_state}
    end
  end

  def handle_call({:delete_user, userid}, _from, state) do
    case Map.get(state.users, userid) do
      nil ->
        {:reply, {:error, "User #{userid} not found"}, state}

      _user ->
        # Also clean up any API tokens for this user
        tokens_to_remove =
          state.api_tokens
          |> Enum.filter(fn {tokenid, _token} -> String.starts_with?(tokenid, "#{userid}!") end)
          |> Enum.map(&elem(&1, 0))

        new_tokens = Enum.reduce(tokens_to_remove, state.api_tokens, &Map.delete(&2, &1))
        new_users = Map.delete(state.users, userid)

        new_state = %{state | users: new_users, api_tokens: new_tokens}
        {:reply, :ok, new_state}
    end
  end

  # Group management callbacks
  def handle_call({:create_group, groupid, params}, _from, state) do
    if Map.has_key?(state.groups, groupid) do
      {:reply, {:error, "Group #{groupid} already exists"}, state}
    else
      group =
        Map.merge(
          %{
            groupid: groupid,
            comment: ""
          },
          params
        )

      new_groups = Map.put(state.groups, groupid, group)
      new_state = %{state | groups: new_groups}

      {:reply, {:ok, group}, new_state}
    end
  end

  def handle_call({:update_group, groupid, params}, _from, state) do
    case Map.get(state.groups, groupid) do
      nil ->
        {:reply, {:error, "Group #{groupid} not found"}, state}

      group ->
        updated_group = Map.merge(group, params)
        new_groups = Map.put(state.groups, groupid, updated_group)
        new_state = %{state | groups: new_groups}
        {:reply, {:ok, updated_group}, new_state}
    end
  end

  def handle_call({:delete_group, groupid}, _from, state) do
    case Map.get(state.groups, groupid) do
      nil ->
        {:reply, {:error, "Group #{groupid} not found"}, state}

      _group ->
        new_groups = Map.delete(state.groups, groupid)
        new_state = %{state | groups: new_groups}
        {:reply, :ok, new_state}
    end
  end

  # API Token management callbacks
  def handle_call({:delete_api_token, tokenid}, _from, state) do
    case Map.get(state.api_tokens, tokenid) do
      nil ->
        {:reply, {:error, "Token #{tokenid} not found"}, state}

      _token ->
        new_tokens = Map.delete(state.api_tokens, tokenid)
        new_state = %{state | api_tokens: new_tokens}
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:update_api_token, tokenid, params}, _from, state) do
    case Map.get(state.api_tokens, tokenid) do
      nil ->
        {:reply, {:error, "Token #{tokenid} not found"}, state}

      token ->
        # Only allow updating certain fields, not the actual token value
        allowed_updates = Map.take(params, [:comment, :expire, :privsep])
        updated_token = Map.merge(token, allowed_updates)
        new_tokens = Map.put(state.api_tokens, tokenid, updated_token)
        new_state = %{state | api_tokens: new_tokens}
        {:reply, {:ok, updated_token}, new_state}
    end
  end

  # Cluster management callbacks
  def handle_call(:get_cluster_status, _from, state) do
    cluster_nodes =
      state.nodes
      |> Enum.map(fn {node_name, node_data} ->
        cluster_node = get_in(state, [:cluster_config, :nodes, node_name]) || %{}

        Map.merge(node_data, %{
          type: "node",
          level: "",
          nodeid: Map.get(cluster_node, :nodeid, 1),
          local: node_name == "pve-node1"
        })
      end)

    {:reply, cluster_nodes, state}
  end

  def handle_call({:join_cluster, hostname, nodeid, votes}, _from, state) do
    # Generate a new node name based on the hostname
    new_node_name = hostname
    new_nodeid = nodeid || map_size(state.cluster_config.nodes) + 1

    # Create new node configuration
    new_node = %{
      name: new_node_name,
      nodeid: new_nodeid,
      votes: votes,
      ring0_addr: "192.168.1.#{20 + new_nodeid}",
      quorum_votes: votes,
      online: true
    }

    # Update cluster configuration
    updated_cluster_config =
      state.cluster_config
      |> put_in([:nodes, new_node_name], new_node)
      |> update_in([:expected_votes], &(&1 + votes))
      |> put_in([:quorum, :expected_votes], state.cluster_config.expected_votes + votes)
      |> put_in([:quorum, :total_votes], state.cluster_config.quorum.total_votes + votes)

    # Add node to main nodes state
    default_node = %{
      node: new_node_name,
      status: "online",
      cpu: 0.05,
      maxcpu: 4,
      # 2GB
      mem: 2_147_483_648,
      # 8GB
      maxmem: 8_589_934_592,
      # 30GB
      disk: 30_000_000_000,
      # 100GB
      maxdisk: 100_000_000_000,
      uptime: 3600,
      version: state.pve_version,
      kernel: "6.2.16-15-pve"
    }

    updated_nodes = Map.put(state.nodes, new_node_name, default_node)

    # Create join task
    task_result =
      handle_call({:create_task, new_node_name, "clusterjoin", %{hostname: hostname}}, nil, %{
        state
        | cluster_config: updated_cluster_config,
          nodes: updated_nodes
      })

    {:reply, {:ok, upid}, final_state} = task_result

    {:reply, {:ok, upid}, final_state}
  end

  def handle_call(:get_cluster_config, _from, state) do
    {:reply, state.cluster_config, state}
  end

  def handle_call({:update_cluster_config, params}, _from, state) do
    updated_config =
      Enum.reduce(params, state.cluster_config, fn {key, value}, acc ->
        case key do
          "cluster_name" -> Map.put(acc, :cluster_name, value)
          _ -> acc
        end
      end)

    new_state = %{state | cluster_config: updated_config}
    {:reply, {:ok, updated_config}, new_state}
  end

  def handle_call(:get_cluster_nodes_config, _from, state) do
    nodes_list =
      state.cluster_config.nodes
      |> Enum.map(fn {_name, node_config} -> node_config end)

    {:reply, nodes_list, state}
  end

  def handle_call({:remove_cluster_node, node_name}, _from, state) do
    case get_in(state, [:cluster_config, :nodes, node_name]) do
      nil ->
        {:reply, {:error, "Node #{node_name} not found in cluster"}, state}

      node_config ->
        votes = Map.get(node_config, :votes, 1)

        # Update cluster configuration
        updated_cluster_config =
          state.cluster_config
          |> put_in([:nodes], Map.delete(state.cluster_config.nodes, node_name))
          |> update_in([:expected_votes], &(&1 - votes))
          |> put_in([:quorum, :expected_votes], state.cluster_config.expected_votes - votes)
          |> put_in([:quorum, :total_votes], state.cluster_config.quorum.total_votes - votes)

        # Remove from main nodes state
        updated_nodes = Map.delete(state.nodes, node_name)

        # Create removal task
        task_result =
          handle_call({:create_task, node_name, "clusterremove", %{node: node_name}}, nil, %{
            state
            | cluster_config: updated_cluster_config,
              nodes: updated_nodes
          })

        {:reply, {:ok, upid}, final_state} = task_result
        {:reply, {:ok, upid}, final_state}
    end
  end

  # HA resource callbacks
  def handle_call(:list_ha_resources, _from, state) do
    {:reply, Map.values(state.ha_resources), state}
  end

  def handle_call({:get_ha_resource, sid}, _from, state) do
    {:reply, Map.get(state.ha_resources, sid), state}
  end

  def handle_call({:create_ha_resource, sid, params}, _from, state) do
    if Map.has_key?(state.ha_resources, sid) do
      {:reply, {:error, "HA resource '#{sid}' already exists"}, state}
    else
      resource = %{
        sid: sid,
        state: Map.get(params, "state", "started"),
        group: Map.get(params, "group"),
        max_restart: Map.get(params, "max_restart", 1),
        max_relocate: Map.get(params, "max_relocate", 1),
        comment: Map.get(params, "comment", ""),
        type: ha_resource_type(sid),
        digest: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      }

      new_resources = Map.put(state.ha_resources, sid, resource)
      {:reply, {:ok, resource}, %{state | ha_resources: new_resources}}
    end
  end

  def handle_call({:update_ha_resource, sid, params}, _from, state) do
    case Map.get(state.ha_resources, sid) do
      nil ->
        {:reply, {:error, "HA resource '#{sid}' not found"}, state}

      resource ->
        updated =
          Enum.reduce(params, resource, fn
            {"state", v}, acc -> Map.put(acc, :state, v)
            {"group", v}, acc -> Map.put(acc, :group, v)
            {"max_restart", v}, acc -> Map.put(acc, :max_restart, v)
            {"max_relocate", v}, acc -> Map.put(acc, :max_relocate, v)
            {"comment", v}, acc -> Map.put(acc, :comment, v)
            _, acc -> acc
          end)

        new_resources = Map.put(state.ha_resources, sid, updated)
        {:reply, {:ok, updated}, %{state | ha_resources: new_resources}}
    end
  end

  def handle_call({:delete_ha_resource, sid}, _from, state) do
    case Map.get(state.ha_resources, sid) do
      nil ->
        {:reply, {:error, "HA resource '#{sid}' not found"}, state}

      _resource ->
        new_resources = Map.delete(state.ha_resources, sid)
        {:reply, :ok, %{state | ha_resources: new_resources}}
    end
  end

  # HA group callbacks
  def handle_call(:list_ha_groups, _from, state) do
    {:reply, Map.values(state.ha_groups), state}
  end

  def handle_call({:get_ha_group, group}, _from, state) do
    {:reply, Map.get(state.ha_groups, group), state}
  end

  def handle_call({:create_ha_group, group, params}, _from, state) do
    if Map.has_key?(state.ha_groups, group) do
      {:reply, {:error, "HA group '#{group}' already exists"}, state}
    else
      ha_group = %{
        group: group,
        nodes: Map.get(params, "nodes", ""),
        restricted: Map.get(params, "restricted", 0),
        nofailback: Map.get(params, "nofailback", 0),
        comment: Map.get(params, "comment", ""),
        type: "group",
        digest: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      }

      new_groups = Map.put(state.ha_groups, group, ha_group)
      {:reply, {:ok, ha_group}, %{state | ha_groups: new_groups}}
    end
  end

  def handle_call({:update_ha_group, group, params}, _from, state) do
    case Map.get(state.ha_groups, group) do
      nil ->
        {:reply, {:error, "HA group '#{group}' not found"}, state}

      ha_group ->
        updated =
          Enum.reduce(params, ha_group, fn
            {"nodes", v}, acc -> Map.put(acc, :nodes, v)
            {"restricted", v}, acc -> Map.put(acc, :restricted, v)
            {"nofailback", v}, acc -> Map.put(acc, :nofailback, v)
            {"comment", v}, acc -> Map.put(acc, :comment, v)
            _, acc -> acc
          end)

        new_groups = Map.put(state.ha_groups, group, updated)
        {:reply, {:ok, updated}, %{state | ha_groups: new_groups}}
    end
  end

  def handle_call({:delete_ha_group, group}, _from, state) do
    case Map.get(state.ha_groups, group) do
      nil ->
        {:reply, {:error, "HA group '#{group}' not found"}, state}

      _group ->
        new_groups = Map.delete(state.ha_groups, group)
        {:reply, :ok, %{state | ha_groups: new_groups}}
    end
  end

  # HA affinity rule callbacks
  def handle_call(:list_ha_affinity_rules, _from, state) do
    {:reply, Map.values(state.ha_affinity_rules), state}
  end

  def handle_call({:get_ha_affinity_rule, rule}, _from, state) do
    {:reply, Map.get(state.ha_affinity_rules, rule), state}
  end

  def handle_call({:create_ha_affinity_rule, rule, params}, _from, state) do
    if Map.has_key?(state.ha_affinity_rules, rule) do
      {:reply, {:error, "HA affinity rule '#{rule}' already exists"}, state}
    else
      affinity_rule = %{
        id: rule,
        type: Map.get(params, "type", "affinity"),
        resources: Map.get(params, "resources", ""),
        comment: Map.get(params, "comment", ""),
        enabled: Map.get(params, "enabled", 1),
        digest: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      }

      new_rules = Map.put(state.ha_affinity_rules, rule, affinity_rule)
      {:reply, {:ok, affinity_rule}, %{state | ha_affinity_rules: new_rules}}
    end
  end

  def handle_call({:update_ha_affinity_rule, rule, params}, _from, state) do
    case Map.get(state.ha_affinity_rules, rule) do
      nil ->
        {:reply, {:error, "HA affinity rule '#{rule}' not found"}, state}

      affinity_rule ->
        updated =
          Enum.reduce(params, affinity_rule, fn
            {"type", v}, acc -> Map.put(acc, :type, v)
            {"resources", v}, acc -> Map.put(acc, :resources, v)
            {"comment", v}, acc -> Map.put(acc, :comment, v)
            {"enabled", v}, acc -> Map.put(acc, :enabled, v)
            _, acc -> acc
          end)

        new_rules = Map.put(state.ha_affinity_rules, rule, updated)
        {:reply, {:ok, updated}, %{state | ha_affinity_rules: new_rules}}
    end
  end

  def handle_call({:delete_ha_affinity_rule, rule}, _from, state) do
    case Map.get(state.ha_affinity_rules, rule) do
      nil ->
        {:reply, {:error, "HA affinity rule '#{rule}' not found"}, state}

      _rule ->
        new_rules = Map.delete(state.ha_affinity_rules, rule)
        {:reply, :ok, %{state | ha_affinity_rules: new_rules}}
    end
  end

  # HA status callback
  def handle_call(:get_ha_status, _from, state) do
    manager_status = %{
      type: "manager",
      status: "active",
      node: "pve-node1",
      timestamp: :os.system_time(:second),
      id: "master"
    }

    resource_statuses =
      state.ha_resources
      |> Enum.map(fn {_sid, resource} ->
        %{
          type: "service",
          sid: resource.sid,
          state: resource.state,
          node: "pve-node1",
          status: "active",
          crm_state: "started",
          max_restart: resource.max_restart,
          max_relocate: resource.max_relocate,
          request_state: resource.state
        }
      end)

    {:reply, [manager_status | resource_statuses], state}
  end

  # Backup job callbacks
  def handle_call(:list_backup_jobs, _from, state) do
    {:reply, Map.values(state.backup_jobs), state}
  end

  def handle_call({:get_backup_job, id}, _from, state) do
    {:reply, Map.get(state.backup_jobs, id), state}
  end

  def handle_call({:create_backup_job, params}, _from, state) do
    id = "backup-#{state.next_backup_job_id}"

    job = %{
      id: id,
      type: "vzdump",
      enabled: Map.get(params, "enabled", 1),
      schedule: Map.get(params, "schedule", "sat 01:00"),
      storage: Map.get(params, "storage", "local"),
      mode: Map.get(params, "mode", "snapshot"),
      compress: Map.get(params, "compress", "zstd"),
      vmid: Map.get(params, "vmid"),
      all: Map.get(params, "all", 0),
      mailto: Map.get(params, "mailto", ""),
      mailnotification: Map.get(params, "mailnotification", "always"),
      comment: Map.get(params, "comment", "")
    }

    new_jobs = Map.put(state.backup_jobs, id, job)

    {:reply, {:ok, job},
     %{state | backup_jobs: new_jobs, next_backup_job_id: state.next_backup_job_id + 1}}
  end

  def handle_call({:update_backup_job, id, params}, _from, state) do
    case Map.get(state.backup_jobs, id) do
      nil ->
        {:reply, {:error, "Backup job '#{id}' not found"}, state}

      job ->
        updated =
          Enum.reduce(params, job, fn
            {"enabled", v}, acc -> Map.put(acc, :enabled, v)
            {"schedule", v}, acc -> Map.put(acc, :schedule, v)
            {"storage", v}, acc -> Map.put(acc, :storage, v)
            {"mode", v}, acc -> Map.put(acc, :mode, v)
            {"compress", v}, acc -> Map.put(acc, :compress, v)
            {"vmid", v}, acc -> Map.put(acc, :vmid, v)
            {"all", v}, acc -> Map.put(acc, :all, v)
            {"mailto", v}, acc -> Map.put(acc, :mailto, v)
            {"comment", v}, acc -> Map.put(acc, :comment, v)
            _, acc -> acc
          end)

        new_jobs = Map.put(state.backup_jobs, id, updated)
        {:reply, {:ok, updated}, %{state | backup_jobs: new_jobs}}
    end
  end

  def handle_call({:delete_backup_job, id}, _from, state) do
    case Map.get(state.backup_jobs, id) do
      nil ->
        {:reply, {:error, "Backup job '#{id}' not found"}, state}

      _job ->
        new_jobs = Map.delete(state.backup_jobs, id)
        {:reply, :ok, %{state | backup_jobs: new_jobs}}
    end
  end

  def handle_call({:get_backup_job_volumes, id}, _from, state) do
    case Map.get(state.backup_jobs, id) do
      nil ->
        {:reply, {:error, "Backup job '#{id}' not found"}, state}

      job ->
        volumes =
          if job.all == 1 do
            all_vmids = Map.keys(state.vms) ++ Map.keys(state.containers)
            Enum.map(all_vmids, fn vmid -> %{vmid: vmid, included: true, reason: "all"} end)
          else
            case job.vmid do
              nil ->
                []

              vmid_str when is_binary(vmid_str) ->
                vmid_str
                |> String.split(",")
                |> Enum.map(&String.trim/1)
                |> Enum.map(fn vmid_s ->
                  vmid = String.to_integer(vmid_s)
                  %{vmid: vmid, included: true, reason: "explicit"}
                end)

              _ ->
                []
            end
          end

        {:reply, {:ok, volumes}, state}
    end
  end

  def handle_call(:get_not_backed_up, _from, state) do
    backed_up_vmids =
      state.backup_jobs
      |> Enum.flat_map(fn {_id, job} ->
        cond do
          job.all == 1 ->
            Map.keys(state.vms) ++ Map.keys(state.containers)

          is_binary(job.vmid) ->
            job.vmid
            |> String.split(",")
            |> Enum.map(&String.trim/1)
            |> Enum.map(&String.to_integer/1)

          true ->
            []
        end
      end)
      |> MapSet.new()

    not_backed_up =
      (Map.keys(state.vms) ++ Map.keys(state.containers))
      |> Enum.reject(&MapSet.member?(backed_up_vmids, &1))
      |> Enum.map(fn vmid ->
        vm = Map.get(state.vms, vmid)
        ct = Map.get(state.containers, vmid)

        if vm do
          %{vmid: vmid, name: Map.get(vm, :name, ""), type: "qemu"}
        else
          %{vmid: vmid, name: Map.get(ct, :hostname, ""), type: "lxc"}
        end
      end)

    {:reply, not_backed_up, state}
  end

  # Cluster options callbacks
  def handle_call(:get_cluster_options, _from, state) do
    {:reply, state.cluster_options, state}
  end

  def handle_call({:update_cluster_options, params}, _from, state) do
    updated =
      Enum.reduce(params, state.cluster_options, fn
        {"keyboard", v}, acc -> Map.put(acc, :keyboard, v)
        {"language", v}, acc -> Map.put(acc, :language, v)
        {"console", v}, acc -> Map.put(acc, :console, v)
        {"email_from", v}, acc -> Map.put(acc, :email_from, v)
        {"max_workers", v}, acc -> Map.put(acc, :max_workers, v)
        {"migration_type", v}, acc -> Map.put(acc, :migration_type, v)
        _, acc -> acc
      end)

    {:reply, {:ok, updated}, %{state | cluster_options: updated}}
  end

  # Domain CRUD callbacks
  def handle_call({:get_domain, realm}, _from, state) do
    {:reply, Map.get(state.domains, realm), state}
  end

  def handle_call({:create_domain, realm, params}, _from, state) do
    if Map.has_key?(state.domains, realm) do
      {:reply, {:error, "Domain '#{realm}' already exists"}, state}
    else
      domain = %{
        realm: realm,
        type: Map.get(params, "type", "pam"),
        comment: Map.get(params, "comment", ""),
        default: Map.get(params, "default", 0),
        tfa: Map.get(params, "tfa", ""),
        digest: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      }

      new_domains = Map.put(state.domains, realm, domain)
      {:reply, {:ok, domain}, %{state | domains: new_domains}}
    end
  end

  def handle_call({:update_domain, realm, params}, _from, state) do
    case Map.get(state.domains, realm) do
      nil ->
        {:reply, {:error, "Domain '#{realm}' not found"}, state}

      domain ->
        updated =
          Enum.reduce(params, domain, fn
            {"comment", v}, acc -> Map.put(acc, :comment, v)
            {"default", v}, acc -> Map.put(acc, :default, v)
            {"tfa", v}, acc -> Map.put(acc, :tfa, v)
            _, acc -> acc
          end)

        new_domains = Map.put(state.domains, realm, updated)
        {:reply, {:ok, updated}, %{state | domains: new_domains}}
    end
  end

  def handle_call({:delete_domain, realm}, _from, state) do
    case Map.get(state.domains, realm) do
      nil ->
        {:reply, {:error, "Domain '#{realm}' not found"}, state}

      _domain ->
        new_domains = Map.delete(state.domains, realm)
        {:reply, :ok, %{state | domains: new_domains}}
    end
  end

  # Role CRUD callbacks
  def handle_call({:get_role, roleid}, _from, state) do
    {:reply, Map.get(state.roles, roleid), state}
  end

  def handle_call({:create_role, roleid, privs}, _from, state) do
    if Map.has_key?(state.roles, roleid) do
      {:reply, {:error, "Role '#{roleid}' already exists"}, state}
    else
      new_roles = Map.put(state.roles, roleid, privs)
      {:reply, {:ok, privs}, %{state | roles: new_roles}}
    end
  end

  def handle_call({:update_role, roleid, privs}, _from, state) do
    case Map.get(state.roles, roleid) do
      nil ->
        {:reply, {:error, "Role '#{roleid}' not found"}, state}

      _existing ->
        new_roles = Map.put(state.roles, roleid, privs)
        {:reply, {:ok, privs}, %{state | roles: new_roles}}
    end
  end

  def handle_call({:delete_role, roleid}, _from, state) do
    case Map.get(state.roles, roleid) do
      nil ->
        {:reply, {:error, "Role '#{roleid}' not found"}, state}

      _role ->
        new_roles = Map.delete(state.roles, roleid)
        {:reply, :ok, %{state | roles: new_roles}}
    end
  end

  # Password change callback
  def handle_call({:change_password, userid}, _from, state) do
    case Map.get(state.users, userid) do
      nil -> {:reply, {:error, "User '#{userid}' not found"}, state}
      _user -> {:reply, :ok, state}
    end
  end

  # ACL listing callback
  def handle_call(:get_acl, _from, state) do
    acl_list =
      state.permissions
      |> Enum.flat_map(fn {path, users} ->
        Enum.map(users, fn {userid, roles} ->
          %{
            path: path,
            ugid: userid,
            ugid_type: "user",
            roleid: Enum.join(roles, ","),
            propagate: 1,
            type: "user"
          }
        end)
      end)

    {:reply, acl_list, state}
  end

  # SDN zone callbacks
  def handle_call(:list_sdn_zones, _from, state) do
    {:reply, Map.values(state.sdn_zones), state}
  end

  def handle_call({:get_sdn_zone, zone}, _from, state) do
    {:reply, Map.get(state.sdn_zones, zone), state}
  end

  def handle_call({:create_sdn_zone, zone, params}, _from, state) do
    if Map.has_key?(state.sdn_zones, zone) do
      {:reply, {:error, "SDN zone '#{zone}' already exists"}, state}
    else
      sdn_zone = %{
        zone: zone,
        type: Map.get(params, "type", "vxlan"),
        nodes: Map.get(params, "nodes", ""),
        peers: Map.get(params, "peers", ""),
        tag: Map.get(params, "tag"),
        mtu: Map.get(params, "mtu", 1450),
        digest: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      }

      new_zones = Map.put(state.sdn_zones, zone, sdn_zone)
      {:reply, {:ok, sdn_zone}, %{state | sdn_zones: new_zones}}
    end
  end

  def handle_call({:update_sdn_zone, zone, params}, _from, state) do
    case Map.get(state.sdn_zones, zone) do
      nil ->
        {:reply, {:error, "SDN zone '#{zone}' not found"}, state}

      sdn_zone ->
        updated =
          Enum.reduce(params, sdn_zone, fn
            {"type", v}, acc -> Map.put(acc, :type, v)
            {"nodes", v}, acc -> Map.put(acc, :nodes, v)
            {"peers", v}, acc -> Map.put(acc, :peers, v)
            {"tag", v}, acc -> Map.put(acc, :tag, v)
            {"mtu", v}, acc -> Map.put(acc, :mtu, v)
            _, acc -> acc
          end)

        new_zones = Map.put(state.sdn_zones, zone, updated)
        {:reply, {:ok, updated}, %{state | sdn_zones: new_zones}}
    end
  end

  def handle_call({:delete_sdn_zone, zone}, _from, state) do
    case Map.get(state.sdn_zones, zone) do
      nil ->
        {:reply, {:error, "SDN zone '#{zone}' not found"}, state}

      _zone ->
        new_zones = Map.delete(state.sdn_zones, zone)
        {:reply, :ok, %{state | sdn_zones: new_zones}}
    end
  end

  # SDN vnet callbacks
  def handle_call(:list_sdn_vnets, _from, state) do
    {:reply, Map.values(state.sdn_vnets), state}
  end

  def handle_call({:get_sdn_vnet, vnet}, _from, state) do
    {:reply, Map.get(state.sdn_vnets, vnet), state}
  end

  def handle_call({:create_sdn_vnet, vnet, params}, _from, state) do
    if Map.has_key?(state.sdn_vnets, vnet) do
      {:reply, {:error, "SDN vnet '#{vnet}' already exists"}, state}
    else
      sdn_vnet = %{
        vnet: vnet,
        zone: Map.get(params, "zone", ""),
        tag: Map.get(params, "tag"),
        alias: Map.get(params, "alias", ""),
        digest: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      }

      new_vnets = Map.put(state.sdn_vnets, vnet, sdn_vnet)
      {:reply, {:ok, sdn_vnet}, %{state | sdn_vnets: new_vnets}}
    end
  end

  def handle_call({:update_sdn_vnet, vnet, params}, _from, state) do
    case Map.get(state.sdn_vnets, vnet) do
      nil ->
        {:reply, {:error, "SDN vnet '#{vnet}' not found"}, state}

      sdn_vnet ->
        updated =
          Enum.reduce(params, sdn_vnet, fn
            {"zone", v}, acc -> Map.put(acc, :zone, v)
            {"tag", v}, acc -> Map.put(acc, :tag, v)
            {"alias", v}, acc -> Map.put(acc, :alias, v)
            _, acc -> acc
          end)

        new_vnets = Map.put(state.sdn_vnets, vnet, updated)
        {:reply, {:ok, updated}, %{state | sdn_vnets: new_vnets}}
    end
  end

  def handle_call({:delete_sdn_vnet, vnet}, _from, state) do
    case Map.get(state.sdn_vnets, vnet) do
      nil ->
        {:reply, {:error, "SDN vnet '#{vnet}' not found"}, state}

      _vnet ->
        new_vnets = Map.delete(state.sdn_vnets, vnet)
        # Also delete subnets for this vnet
        new_subnets =
          state.sdn_subnets
          |> Enum.reject(fn {{v, _s}, _} -> v == vnet end)
          |> Map.new()

        {:reply, :ok, %{state | sdn_vnets: new_vnets, sdn_subnets: new_subnets}}
    end
  end

  # SDN subnet callbacks
  def handle_call({:list_sdn_subnets, vnet}, _from, state) do
    subnets =
      state.sdn_subnets
      |> Enum.filter(fn {{v, _s}, _} -> v == vnet end)
      |> Enum.map(fn {_key, subnet} -> subnet end)

    {:reply, subnets, state}
  end

  def handle_call({:get_sdn_subnet, vnet, subnet}, _from, state) do
    {:reply, Map.get(state.sdn_subnets, {vnet, subnet}), state}
  end

  def handle_call({:create_sdn_subnet, vnet, subnet, params}, _from, state) do
    key = {vnet, subnet}

    if Map.has_key?(state.sdn_subnets, key) do
      {:reply, {:error, "Subnet '#{subnet}' already exists in vnet '#{vnet}'"}, state}
    else
      sdn_subnet = %{
        subnet: subnet,
        vnet: vnet,
        type: "subnet",
        gateway: Map.get(params, "gateway", ""),
        snat: Map.get(params, "snat", 0),
        dnszoneprefix: Map.get(params, "dnszoneprefix", ""),
        digest: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      }

      new_subnets = Map.put(state.sdn_subnets, key, sdn_subnet)
      {:reply, {:ok, sdn_subnet}, %{state | sdn_subnets: new_subnets}}
    end
  end

  def handle_call({:update_sdn_subnet, vnet, subnet, params}, _from, state) do
    key = {vnet, subnet}

    case Map.get(state.sdn_subnets, key) do
      nil ->
        {:reply, {:error, "Subnet '#{subnet}' not found in vnet '#{vnet}'"}, state}

      sdn_subnet ->
        updated =
          Enum.reduce(params, sdn_subnet, fn
            {"gateway", v}, acc -> Map.put(acc, :gateway, v)
            {"snat", v}, acc -> Map.put(acc, :snat, v)
            {"dnszoneprefix", v}, acc -> Map.put(acc, :dnszoneprefix, v)
            _, acc -> acc
          end)

        new_subnets = Map.put(state.sdn_subnets, key, updated)
        {:reply, {:ok, updated}, %{state | sdn_subnets: new_subnets}}
    end
  end

  def handle_call({:delete_sdn_subnet, vnet, subnet}, _from, state) do
    key = {vnet, subnet}

    case Map.get(state.sdn_subnets, key) do
      nil ->
        {:reply, {:error, "Subnet '#{subnet}' not found in vnet '#{vnet}'"}, state}

      _subnet ->
        new_subnets = Map.delete(state.sdn_subnets, key)
        {:reply, :ok, %{state | sdn_subnets: new_subnets}}
    end
  end

  # SDN controller callbacks
  def handle_call(:list_sdn_controllers, _from, state) do
    {:reply, Map.values(state.sdn_controllers), state}
  end

  def handle_call({:get_sdn_controller, controller}, _from, state) do
    {:reply, Map.get(state.sdn_controllers, controller), state}
  end

  def handle_call({:create_sdn_controller, controller, params}, _from, state) do
    if Map.has_key?(state.sdn_controllers, controller) do
      {:reply, {:error, "SDN controller '#{controller}' already exists"}, state}
    else
      sdn_controller = %{
        controller: controller,
        type: Map.get(params, "type", "evpn"),
        asn: Map.get(params, "asn"),
        peers: Map.get(params, "peers", ""),
        digest: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      }

      new_controllers = Map.put(state.sdn_controllers, controller, sdn_controller)
      {:reply, {:ok, sdn_controller}, %{state | sdn_controllers: new_controllers}}
    end
  end

  def handle_call({:update_sdn_controller, controller, params}, _from, state) do
    case Map.get(state.sdn_controllers, controller) do
      nil ->
        {:reply, {:error, "SDN controller '#{controller}' not found"}, state}

      sdn_controller ->
        updated =
          Enum.reduce(params, sdn_controller, fn
            {"type", v}, acc -> Map.put(acc, :type, v)
            {"asn", v}, acc -> Map.put(acc, :asn, v)
            {"peers", v}, acc -> Map.put(acc, :peers, v)
            _, acc -> acc
          end)

        new_controllers = Map.put(state.sdn_controllers, controller, updated)
        {:reply, {:ok, updated}, %{state | sdn_controllers: new_controllers}}
    end
  end

  def handle_call({:delete_sdn_controller, controller}, _from, state) do
    case Map.get(state.sdn_controllers, controller) do
      nil ->
        {:reply, {:error, "SDN controller '#{controller}' not found"}, state}

      _controller ->
        new_controllers = Map.delete(state.sdn_controllers, controller)
        {:reply, :ok, %{state | sdn_controllers: new_controllers}}
    end
  end

  # SDN DNS handle_calls

  def handle_call(:list_sdn_dns, _from, state) do
    {:reply, Map.values(state.sdn_dns), state}
  end

  def handle_call({:get_sdn_dns, dns}, _from, state) do
    {:reply, Map.get(state.sdn_dns, dns), state}
  end

  def handle_call({:create_sdn_dns, dns, params}, _from, state) do
    if Map.has_key?(state.sdn_dns, dns) do
      {:reply, {:error, "SDN DNS plugin '#{dns}' already exists"}, state}
    else
      sdn_dns = %{
        dns: dns,
        type: Map.get(params, "type", "powerdns"),
        url: Map.get(params, "url", ""),
        key: Map.get(params, "key"),
        reversev6mask: Map.get(params, "reversev6mask"),
        ttl: Map.get(params, "ttl"),
        digest: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      }

      new_dns = Map.put(state.sdn_dns, dns, sdn_dns)
      {:reply, {:ok, sdn_dns}, %{state | sdn_dns: new_dns}}
    end
  end

  def handle_call({:update_sdn_dns, dns, params}, _from, state) do
    case Map.get(state.sdn_dns, dns) do
      nil ->
        {:reply, {:error, "SDN DNS plugin '#{dns}' not found"}, state}

      sdn_dns ->
        updated =
          Enum.reduce(params, sdn_dns, fn
            {"type", v}, acc -> Map.put(acc, :type, v)
            {"url", v}, acc -> Map.put(acc, :url, v)
            {"key", v}, acc -> Map.put(acc, :key, v)
            {"reversev6mask", v}, acc -> Map.put(acc, :reversev6mask, v)
            {"ttl", v}, acc -> Map.put(acc, :ttl, v)
            _, acc -> acc
          end)

        new_dns = Map.put(state.sdn_dns, dns, updated)
        {:reply, {:ok, updated}, %{state | sdn_dns: new_dns}}
    end
  end

  def handle_call({:delete_sdn_dns, dns}, _from, state) do
    case Map.get(state.sdn_dns, dns) do
      nil ->
        {:reply, {:error, "SDN DNS plugin '#{dns}' not found"}, state}

      _dns ->
        new_dns = Map.delete(state.sdn_dns, dns)
        {:reply, :ok, %{state | sdn_dns: new_dns}}
    end
  end

  # SDN IPAM handle_calls

  def handle_call(:list_sdn_ipams, _from, state) do
    {:reply, Map.values(state.sdn_ipams), state}
  end

  def handle_call({:get_sdn_ipam, ipam}, _from, state) do
    {:reply, Map.get(state.sdn_ipams, ipam), state}
  end

  def handle_call({:create_sdn_ipam, ipam, params}, _from, state) do
    if Map.has_key?(state.sdn_ipams, ipam) do
      {:reply, {:error, "SDN IPAM '#{ipam}' already exists"}, state}
    else
      sdn_ipam = %{
        ipam: ipam,
        type: Map.get(params, "type", "pve"),
        url: Map.get(params, "url"),
        token: Map.get(params, "token"),
        section: Map.get(params, "section"),
        digest: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      }

      new_ipams = Map.put(state.sdn_ipams, ipam, sdn_ipam)
      {:reply, {:ok, sdn_ipam}, %{state | sdn_ipams: new_ipams}}
    end
  end

  def handle_call({:update_sdn_ipam, ipam, params}, _from, state) do
    case Map.get(state.sdn_ipams, ipam) do
      nil ->
        {:reply, {:error, "SDN IPAM '#{ipam}' not found"}, state}

      sdn_ipam ->
        updated =
          Enum.reduce(params, sdn_ipam, fn
            {"type", v}, acc -> Map.put(acc, :type, v)
            {"url", v}, acc -> Map.put(acc, :url, v)
            {"token", v}, acc -> Map.put(acc, :token, v)
            {"section", v}, acc -> Map.put(acc, :section, v)
            _, acc -> acc
          end)

        new_ipams = Map.put(state.sdn_ipams, ipam, updated)
        {:reply, {:ok, updated}, %{state | sdn_ipams: new_ipams}}
    end
  end

  def handle_call({:delete_sdn_ipam, ipam}, _from, state) do
    case Map.get(state.sdn_ipams, ipam) do
      nil ->
        {:reply, {:error, "SDN IPAM '#{ipam}' not found"}, state}

      _ipam ->
        new_ipams = Map.delete(state.sdn_ipams, ipam)
        {:reply, :ok, %{state | sdn_ipams: new_ipams}}
    end
  end

  # PCI mapping handle_calls

  def handle_call(:list_pci_mappings, _from, state) do
    {:reply, Map.values(state.pci_mappings), state}
  end

  def handle_call({:get_pci_mapping, id}, _from, state) do
    {:reply, Map.get(state.pci_mappings, id), state}
  end

  def handle_call({:create_pci_mapping, id, params}, _from, state) do
    if Map.has_key?(state.pci_mappings, id) do
      {:reply, {:error, "PCI mapping '#{id}' already exists"}, state}
    else
      mapping = %{
        id: id,
        description: Map.get(params, "description", ""),
        map: Map.get(params, "map", []),
        digest: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      }

      new = Map.put(state.pci_mappings, id, mapping)
      {:reply, {:ok, mapping}, %{state | pci_mappings: new}}
    end
  end

  def handle_call({:update_pci_mapping, id, params}, _from, state) do
    case Map.get(state.pci_mappings, id) do
      nil ->
        {:reply, {:error, "PCI mapping '#{id}' not found"}, state}

      mapping ->
        updated =
          Enum.reduce(params, mapping, fn
            {"description", v}, acc -> Map.put(acc, :description, v)
            {"map", v}, acc -> Map.put(acc, :map, v)
            _, acc -> acc
          end)

        new = Map.put(state.pci_mappings, id, updated)
        {:reply, {:ok, updated}, %{state | pci_mappings: new}}
    end
  end

  def handle_call({:delete_pci_mapping, id}, _from, state) do
    case Map.get(state.pci_mappings, id) do
      nil ->
        {:reply, {:error, "PCI mapping '#{id}' not found"}, state}

      _ ->
        new = Map.delete(state.pci_mappings, id)
        {:reply, :ok, %{state | pci_mappings: new}}
    end
  end

  # USB mapping handle_calls

  def handle_call(:list_usb_mappings, _from, state) do
    {:reply, Map.values(state.usb_mappings), state}
  end

  def handle_call({:get_usb_mapping, id}, _from, state) do
    {:reply, Map.get(state.usb_mappings, id), state}
  end

  def handle_call({:create_usb_mapping, id, params}, _from, state) do
    if Map.has_key?(state.usb_mappings, id) do
      {:reply, {:error, "USB mapping '#{id}' already exists"}, state}
    else
      mapping = %{
        id: id,
        description: Map.get(params, "description", ""),
        map: Map.get(params, "map", []),
        digest: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      }

      new = Map.put(state.usb_mappings, id, mapping)
      {:reply, {:ok, mapping}, %{state | usb_mappings: new}}
    end
  end

  def handle_call({:update_usb_mapping, id, params}, _from, state) do
    case Map.get(state.usb_mappings, id) do
      nil ->
        {:reply, {:error, "USB mapping '#{id}' not found"}, state}

      mapping ->
        updated =
          Enum.reduce(params, mapping, fn
            {"description", v}, acc -> Map.put(acc, :description, v)
            {"map", v}, acc -> Map.put(acc, :map, v)
            _, acc -> acc
          end)

        new = Map.put(state.usb_mappings, id, updated)
        {:reply, {:ok, updated}, %{state | usb_mappings: new}}
    end
  end

  def handle_call({:delete_usb_mapping, id}, _from, state) do
    case Map.get(state.usb_mappings, id) do
      nil ->
        {:reply, {:error, "USB mapping '#{id}' not found"}, state}

      _ ->
        new = Map.delete(state.usb_mappings, id)
        {:reply, :ok, %{state | usb_mappings: new}}
    end
  end

  # Storage CRUD handle_calls

  def handle_call({:get_storage_by_id, storage_id}, _from, state) do
    {:reply, Map.get(state.storage, storage_id), state}
  end

  def handle_call({:get_storage_status, storage_id}, _from, state) do
    case Map.get(state.storage, storage_id) do
      nil ->
        {:reply, nil, state}

      storage ->
        status = %{
          storage: storage_id,
          type: storage.type,
          content: storage.content,
          enabled: Map.get(storage, :enabled, 1),
          active: 1,
          shared: 0,
          # 100 GiB synthetic
          total: 107_374_182_400,
          # 50 GiB synthetic
          used: 53_687_091_200,
          # 50 GiB synthetic
          avail: 53_687_091_200
        }

        {:reply, status, state}
    end
  end

  def handle_call({:create_storage, storage_id, params}, _from, state) do
    if Map.has_key?(state.storage, storage_id) do
      {:reply, {:error, "Storage '#{storage_id}' already exists"}, state}
    else
      storage = %{
        storage: storage_id,
        type: Map.get(params, "type", "dir"),
        content: Map.get(params, "content", "images"),
        path: Map.get(params, "path"),
        nodes: Map.get(params, "nodes", ""),
        enabled: Map.get(params, "enabled", 1),
        shared: Map.get(params, "shared", 0),
        digest: "mock-digest-#{System.unique_integer([:positive])}"
      }

      new_storage = Map.put(state.storage, storage_id, storage)
      {:reply, {:ok, storage}, %{state | storage: new_storage}}
    end
  end

  def handle_call({:update_storage, storage_id, params}, _from, state) do
    case Map.get(state.storage, storage_id) do
      nil ->
        {:reply, {:error, "Storage '#{storage_id}' not found"}, state}

      existing ->
        updates =
          Enum.reduce(params, existing, fn
            {"type", v}, acc -> Map.put(acc, :type, v)
            {"content", v}, acc -> Map.put(acc, :content, v)
            {"path", v}, acc -> Map.put(acc, :path, v)
            {"nodes", v}, acc -> Map.put(acc, :nodes, v)
            {"enabled", v}, acc -> Map.put(acc, :enabled, v)
            {"shared", v}, acc -> Map.put(acc, :shared, v)
            {"disable", v}, acc -> Map.put(acc, :disable, v)
            _, acc -> acc
          end)

        new_storage = Map.put(state.storage, storage_id, updates)
        {:reply, {:ok, updates}, %{state | storage: new_storage}}
    end
  end

  def handle_call({:delete_storage, storage_id}, _from, state) do
    case Map.get(state.storage, storage_id) do
      nil ->
        {:reply, {:error, "Storage '#{storage_id}' not found"}, state}

      _storage ->
        new_storage = Map.delete(state.storage, storage_id)
        {:reply, :ok, %{state | storage: new_storage}}
    end
  end

  # Storage volume operations

  def handle_call({:get_storage_volume, _node, storage_id, volume}, _from, state) do
    key = {storage_id, volume}

    case Map.get(state.storage_content, key) do
      nil ->
        # Check if storage exists at all
        if Map.has_key?(state.storage, storage_id) do
          {:reply, nil, state}
        else
          {:reply, {:error, "Storage '#{storage_id}' not found"}, state}
        end

      content ->
        {:reply, content, state}
    end
  end

  def handle_call({:delete_storage_volume, _node, storage_id, volume}, _from, state) do
    key = {storage_id, volume}

    case Map.get(state.storage_content, key) do
      nil ->
        {:reply, {:error, "Volume '#{volume}' not found"}, state}

      _content ->
        new_content = Map.delete(state.storage_content, key)
        {:reply, :ok, %{state | storage_content: new_content}}
    end
  end

  # Node DNS handle_calls

  def handle_call({:get_node_dns, node}, _from, state) do
    dns =
      Map.get(state.node_dns, node, %{
        dns1: "8.8.8.8",
        dns2: "8.8.4.4",
        dns3: "",
        search: "local"
      })

    {:reply, dns, state}
  end

  def handle_call({:update_node_dns, node, params}, _from, state) do
    current = Map.get(state.node_dns, node, %{})

    updated =
      Enum.reduce(params, current, fn
        {"dns1", v}, acc -> Map.put(acc, :dns1, v)
        {"dns2", v}, acc -> Map.put(acc, :dns2, v)
        {"dns3", v}, acc -> Map.put(acc, :dns3, v)
        {"search", v}, acc -> Map.put(acc, :search, v)
        _, acc -> acc
      end)

    new_dns = Map.put(state.node_dns, node, updated)
    {:reply, :ok, %{state | node_dns: new_dns}}
  end

  # Node network interface handle_calls

  def handle_call({:get_node_network_iface, node, iface}, _from, state) do
    result =
      case Map.get(state.node_network_interfaces, node) do
        nil -> nil
        ifaces -> Map.get(ifaces, iface)
      end

    {:reply, result, state}
  end

  def handle_call({:update_node_network_iface, node, iface, params}, _from, state) do
    node_ifaces = Map.get(state.node_network_interfaces, node, %{})

    case Map.get(node_ifaces, iface) do
      nil ->
        {:reply, {:error, "Interface '#{iface}' not found"}, state}

      existing ->
        updated =
          Enum.reduce(params, existing, fn
            {"address", v}, acc -> Map.put(acc, :address, v)
            {"netmask", v}, acc -> Map.put(acc, :netmask, v)
            {"gateway", v}, acc -> Map.put(acc, :gateway, v)
            {"method", v}, acc -> Map.put(acc, :method, v)
            {"autostart", v}, acc -> Map.put(acc, :autostart, v)
            {"bridge_ports", v}, acc -> Map.put(acc, :bridge_ports, v)
            {"mtu", v}, acc -> Map.put(acc, :mtu, v)
            _, acc -> acc
          end)

        new_ifaces = Map.put(node_ifaces, iface, updated)
        new_all = Map.put(state.node_network_interfaces, node, new_ifaces)
        {:reply, {:ok, updated}, %{state | node_network_interfaces: new_all}}
    end
  end

  def handle_call({:delete_node_network_iface, node, iface}, _from, state) do
    node_ifaces = Map.get(state.node_network_interfaces, node, %{})

    case Map.get(node_ifaces, iface) do
      nil ->
        {:reply, {:error, "Interface '#{iface}' not found"}, state}

      _existing ->
        new_ifaces = Map.delete(node_ifaces, iface)
        new_all = Map.put(state.node_network_interfaces, node, new_ifaces)
        {:reply, :ok, %{state | node_network_interfaces: new_all}}
    end
  end

  # Node config handle_calls

  def handle_call({:get_node_config, node}, _from, state) do
    config =
      Map.get(state.node_configs, node, %{
        description: "",
        wakeonlan: "",
        startall_onboot_delay: 0
      })

    {:reply, config, state}
  end

  def handle_call({:update_node_config, node, params}, _from, state) do
    current = Map.get(state.node_configs, node, %{})

    updated =
      Enum.reduce(params, current, fn
        {"description", v}, acc -> Map.put(acc, :description, v)
        {"wakeonlan", v}, acc -> Map.put(acc, :wakeonlan, v)
        {"startall-onboot-delay", v}, acc -> Map.put(acc, :startall_onboot_delay, v)
        _, acc -> acc
      end)

    new_configs = Map.put(state.node_configs, node, updated)
    {:reply, :ok, %{state | node_configs: new_configs}}
  end

  # Task delete handle_call

  def handle_call({:delete_task, upid}, _from, state) do
    case Map.get(state.tasks, upid) do
      nil ->
        {:reply, {:error, "Task '#{upid}' not found"}, state}

      _task ->
        new_tasks = Map.delete(state.tasks, upid)
        {:reply, :ok, %{state | tasks: new_tasks}}
    end
  end

  # VM/Container resize handle_calls

  def handle_call({:resize_vm_disk, node, vmid, disk, size}, _from, state) do
    case Map.get(state.vms, vmid) do
      nil ->
        {:reply, {:error, :not_found}, state}

      vm when vm.node == node ->
        updated_vm = Map.put(vm, String.to_atom(disk), size)
        new_vms = Map.put(state.vms, vmid, updated_vm)
        {:reply, :ok, %{state | vms: new_vms}}

      _ ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:resize_container_disk, node, vmid, disk, size}, _from, state) do
    case Map.get(state.containers, vmid) do
      nil ->
        {:reply, {:error, :not_found}, state}

      ct when ct.node == node ->
        updated_ct = Map.put(ct, String.to_atom(disk), size)
        new_containers = Map.put(state.containers, vmid, updated_ct)
        {:reply, :ok, %{state | containers: new_containers}}

      _ ->
        {:reply, {:error, :not_found}, state}
    end
  end

  # Replication handle_calls

  def handle_call(:list_replication_jobs, _from, state) do
    jobs = Map.values(state.replication_jobs)
    {:reply, jobs, state}
  end

  def handle_call({:create_replication_job, id, params}, _from, state) do
    if Map.has_key?(state.replication_jobs, id) do
      {:reply, {:error, :already_exists}, state}
    else
      job =
        Map.merge(
          %{
            id: id,
            type: "local",
            source: "",
            target: "",
            guest: nil,
            schedule: "*/15",
            rate: nil,
            comment: "",
            disable: 0,
            remove_job: "full"
          },
          params
        )

      new_jobs = Map.put(state.replication_jobs, id, job)
      {:reply, {:ok, job}, %{state | replication_jobs: new_jobs}}
    end
  end

  def handle_call({:get_replication_job, id}, _from, state) do
    case Map.get(state.replication_jobs, id) do
      nil -> {:reply, nil, state}
      job -> {:reply, job, state}
    end
  end

  def handle_call({:update_replication_job, id, params}, _from, state) do
    case Map.get(state.replication_jobs, id) do
      nil ->
        {:reply, {:error, "Replication job '#{id}' not found"}, state}

      job ->
        updated = Map.merge(job, params)
        new_jobs = Map.put(state.replication_jobs, id, updated)
        {:reply, {:ok, updated}, %{state | replication_jobs: new_jobs}}
    end
  end

  def handle_call({:delete_replication_job, id}, _from, state) do
    if Map.has_key?(state.replication_jobs, id) do
      new_jobs = Map.delete(state.replication_jobs, id)
      {:reply, :ok, %{state | replication_jobs: new_jobs}}
    else
      {:reply, {:error, "Replication job '#{id}' not found"}, state}
    end
  end

  # ACME account handle_calls

  def handle_call(:list_acme_accounts, _from, state) do
    {:reply, Map.values(state.acme_accounts), state}
  end

  def handle_call({:get_acme_account, name}, _from, state) do
    {:reply, Map.get(state.acme_accounts, name), state}
  end

  def handle_call({:create_acme_account, name, params}, _from, state) do
    if Map.has_key?(state.acme_accounts, name) do
      {:reply, {:error, :already_exists}, state}
    else
      account =
        Map.merge(
          %{
            name: name,
            contact: "",
            directory: "https://acme-v02.api.letsencrypt.org/directory",
            tos: ""
          },
          params
        )

      new_accounts = Map.put(state.acme_accounts, name, account)
      {:reply, {:ok, account}, %{state | acme_accounts: new_accounts}}
    end
  end

  def handle_call({:update_acme_account, name, params}, _from, state) do
    case Map.get(state.acme_accounts, name) do
      nil ->
        {:reply, {:error, "ACME account '#{name}' not found"}, state}

      account ->
        updated = Map.merge(account, params)
        new_accounts = Map.put(state.acme_accounts, name, updated)
        {:reply, {:ok, updated}, %{state | acme_accounts: new_accounts}}
    end
  end

  def handle_call({:delete_acme_account, name}, _from, state) do
    if Map.has_key?(state.acme_accounts, name) do
      {:reply, :ok, %{state | acme_accounts: Map.delete(state.acme_accounts, name)}}
    else
      {:reply, {:error, "ACME account '#{name}' not found"}, state}
    end
  end

  # ACME plugin handle_calls

  def handle_call(:list_acme_plugins, _from, state) do
    {:reply, Map.values(state.acme_plugins), state}
  end

  def handle_call({:get_acme_plugin, id}, _from, state) do
    {:reply, Map.get(state.acme_plugins, id), state}
  end

  def handle_call({:create_acme_plugin, id, params}, _from, state) do
    if Map.has_key?(state.acme_plugins, id) do
      {:reply, {:error, :already_exists}, state}
    else
      plugin = Map.merge(%{plugin: id, type: "standalone", api: nil}, params)
      new_plugins = Map.put(state.acme_plugins, id, plugin)
      {:reply, {:ok, plugin}, %{state | acme_plugins: new_plugins}}
    end
  end

  def handle_call({:update_acme_plugin, id, params}, _from, state) do
    case Map.get(state.acme_plugins, id) do
      nil ->
        {:reply, {:error, "ACME plugin '#{id}' not found"}, state}

      plugin ->
        updated = Map.merge(plugin, params)
        new_plugins = Map.put(state.acme_plugins, id, updated)
        {:reply, {:ok, updated}, %{state | acme_plugins: new_plugins}}
    end
  end

  def handle_call({:delete_acme_plugin, id}, _from, state) do
    if Map.has_key?(state.acme_plugins, id) do
      {:reply, :ok, %{state | acme_plugins: Map.delete(state.acme_plugins, id)}}
    else
      {:reply, {:error, "ACME plugin '#{id}' not found"}, state}
    end
  end

  # Notification handle_calls

  def handle_call({:list_notification_endpoints, type}, _from, state) do
    key = notification_key(type)
    {:reply, Map.values(Map.get(state, key, %{})), state}
  end

  def handle_call({:get_notification_endpoint, type, name}, _from, state) do
    key = notification_key(type)
    {:reply, Map.get(Map.get(state, key, %{}), name), state}
  end

  def handle_call({:create_notification_endpoint, type, name, params}, _from, state) do
    key = notification_key(type)
    store = Map.get(state, key, %{})

    if Map.has_key?(store, name) do
      {:reply, {:error, :already_exists}, state}
    else
      endpoint = Map.merge(%{name: name, type: to_string(type)}, params)
      new_store = Map.put(store, name, endpoint)
      {:reply, {:ok, endpoint}, Map.put(state, key, new_store)}
    end
  end

  def handle_call({:update_notification_endpoint, type, name, params}, _from, state) do
    key = notification_key(type)
    store = Map.get(state, key, %{})

    case Map.get(store, name) do
      nil ->
        {:reply, {:error, "Notification endpoint '#{name}' not found"}, state}

      endpoint ->
        updated = Map.merge(endpoint, params)
        new_store = Map.put(store, name, updated)
        {:reply, {:ok, updated}, Map.put(state, key, new_store)}
    end
  end

  def handle_call({:delete_notification_endpoint, type, name}, _from, state) do
    key = notification_key(type)
    store = Map.get(state, key, %{})

    if Map.has_key?(store, name) do
      {:reply, :ok, Map.put(state, key, Map.delete(store, name))}
    else
      {:reply, {:error, "Notification endpoint '#{name}' not found"}, state}
    end
  end

  def handle_call(:list_notification_matchers, _from, state) do
    {:reply, Map.values(state.notification_matchers), state}
  end

  def handle_call({:get_notification_matcher, name}, _from, state) do
    {:reply, Map.get(state.notification_matchers, name), state}
  end

  def handle_call({:create_notification_matcher, name, params}, _from, state) do
    if Map.has_key?(state.notification_matchers, name) do
      {:reply, {:error, :already_exists}, state}
    else
      matcher =
        Map.merge(%{name: name, match_severity: nil, match_field: nil, target: nil}, params)

      new_matchers = Map.put(state.notification_matchers, name, matcher)
      {:reply, {:ok, matcher}, %{state | notification_matchers: new_matchers}}
    end
  end

  def handle_call({:update_notification_matcher, name, params}, _from, state) do
    case Map.get(state.notification_matchers, name) do
      nil ->
        {:reply, {:error, "Notification matcher '#{name}' not found"}, state}

      matcher ->
        updated = Map.merge(matcher, params)
        new_matchers = Map.put(state.notification_matchers, name, updated)
        {:reply, {:ok, updated}, %{state | notification_matchers: new_matchers}}
    end
  end

  def handle_call({:delete_notification_matcher, name}, _from, state) do
    if Map.has_key?(state.notification_matchers, name) do
      {:reply, :ok,
       %{state | notification_matchers: Map.delete(state.notification_matchers, name)}}
    else
      {:reply, {:error, "Notification matcher '#{name}' not found"}, state}
    end
  end

  # Firewall handle_calls

  def handle_call({:get_firewall, :cluster}, _from, state) do
    {:reply, state.firewall.cluster, state}
  end

  def handle_call({:get_firewall, {:node, node}}, _from, state) do
    node_fw =
      Map.get(state.firewall.nodes, node, %{
        options: %{enable: 0, log_level_in: "nolog", log_level_out: "nolog"},
        rules: []
      })

    {:reply, node_fw, state}
  end

  def handle_call({:update_firewall, :cluster, updates}, _from, state) do
    new_cluster_fw = Map.merge(state.firewall.cluster, updates)
    new_fw = %{state.firewall | cluster: new_cluster_fw}
    {:reply, :ok, %{state | firewall: new_fw}}
  end

  def handle_call({:update_firewall, {:node, node}, updates}, _from, state) do
    current =
      Map.get(state.firewall.nodes, node, %{
        options: %{enable: 0, log_level_in: "nolog", log_level_out: "nolog"},
        rules: []
      })

    updated = Map.merge(current, updates)
    new_nodes = Map.put(state.firewall.nodes, node, updated)
    new_fw = %{state.firewall | nodes: new_nodes}
    {:reply, :ok, %{state | firewall: new_fw}}
  end

  def handle_call({:get_firewall, {:vm, vmid}}, _from, state) do
    vm_fw = Map.get(state.firewall.vms, vmid, default_vm_ct_firewall())
    {:reply, vm_fw, state}
  end

  def handle_call({:get_firewall, {:container, vmid}}, _from, state) do
    ct_fw = Map.get(state.firewall.containers, vmid, default_vm_ct_firewall())
    {:reply, ct_fw, state}
  end

  def handle_call({:update_firewall, {:vm, vmid}, updates}, _from, state) do
    current = Map.get(state.firewall.vms, vmid, default_vm_ct_firewall())
    updated = Map.merge(current, updates)
    new_vms = Map.put(state.firewall.vms, vmid, updated)
    new_fw = %{state.firewall | vms: new_vms}
    {:reply, :ok, %{state | firewall: new_fw}}
  end

  def handle_call({:update_firewall, {:container, vmid}, updates}, _from, state) do
    current = Map.get(state.firewall.containers, vmid, default_vm_ct_firewall())
    updated = Map.merge(current, updates)
    new_cts = Map.put(state.firewall.containers, vmid, updated)
    new_fw = %{state.firewall | containers: new_cts}
    {:reply, :ok, %{state | firewall: new_fw}}
  end

  # Metrics server handle_calls

  def handle_call(:get_metrics_servers, _from, state) do
    servers = state.metrics_servers |> Map.values()
    {:reply, servers, state}
  end

  def handle_call({:get_metrics_server, id}, _from, state) do
    {:reply, Map.get(state.metrics_servers, id), state}
  end

  def handle_call({:create_metrics_server, id, params}, _from, state) do
    if Map.has_key?(state.metrics_servers, id) do
      {:reply, {:error, "Metrics server '#{id}' already exists"}, state}
    else
      server = Map.merge(%{id: id, type: "influxdb", port: 8089, enable: 1}, params)
      new_servers = Map.put(state.metrics_servers, id, server)
      {:reply, {:ok, server}, %{state | metrics_servers: new_servers}}
    end
  end

  def handle_call({:update_metrics_server, id, params}, _from, state) do
    case Map.get(state.metrics_servers, id) do
      nil ->
        {:reply, {:error, "Metrics server '#{id}' not found"}, state}

      server ->
        updated = Map.merge(server, params)
        new_servers = Map.put(state.metrics_servers, id, updated)
        {:reply, {:ok, updated}, %{state | metrics_servers: new_servers}}
    end
  end

  def handle_call({:delete_metrics_server, id}, _from, state) do
    if Map.has_key?(state.metrics_servers, id) do
      {:reply, :ok, %{state | metrics_servers: Map.delete(state.metrics_servers, id)}}
    else
      {:reply, {:error, "Metrics server '#{id}' not found"}, state}
    end
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    Logger.info("Mock PVE Server state reset")
    {:reply, :ok, initial_state()}
  end

  @impl true
  def handle_cast({:update_node, name, updates}, state) do
    case Map.get(state.nodes, name) do
      nil ->
        {:noreply, state}

      node ->
        updated_node = Map.merge(node, updates)
        new_nodes = Map.put(state.nodes, name, updated_node)
        new_state = %{state | nodes: new_nodes}
        {:noreply, new_state}
    end
  end

  def handle_cast({:delete_vm, node, vmid}, state) do
    case Map.get(state.vms, vmid) do
      nil ->
        {:noreply, state}

      vm when vm.node == node ->
        new_vms = Map.delete(state.vms, vmid)
        new_state = %{state | vms: new_vms}
        {:noreply, new_state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_cast({:delete_container, node, vmid}, state) do
    case Map.get(state.containers, vmid) do
      nil ->
        {:noreply, state}

      container when container.node == node ->
        new_containers = Map.delete(state.containers, vmid)
        new_state = %{state | containers: new_containers}
        {:noreply, new_state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_cast({:delete_pool, poolid}, state) do
    new_pools = Map.delete(state.pools, poolid)
    new_state = %{state | pools: new_pools}
    {:noreply, new_state}
  end

  def handle_cast({:update_task, upid, updates}, state) do
    case Map.get(state.tasks, upid) do
      nil ->
        {:noreply, state}

      task ->
        updated_task = Map.merge(task, updates)
        new_tasks = Map.put(state.tasks, upid, updated_task)
        {:noreply, %{state | tasks: new_tasks}}
    end
  end

  # Private helpers

  defp ha_resource_type(sid) do
    case String.split(sid, ":", parts: 2) do
      ["vm", _] -> "vm"
      ["ct", _] -> "ct"
      _ -> "vm"
    end
  end

  defp notification_key(:gotify), do: :notification_gotify
  defp notification_key(:sendmail), do: :notification_sendmail
  defp notification_key("gotify"), do: :notification_gotify
  defp notification_key("sendmail"), do: :notification_sendmail

  defp default_vm_ct_firewall do
    %{
      options: %{
        enable: 0,
        dhcp: 0,
        ipfilter: 0,
        log_level_in: "nolog",
        log_level_out: "nolog",
        macfilter: 1,
        ndp: 1,
        policy_in: "DROP",
        policy_out: "ACCEPT",
        radv: 0
      },
      rules: [],
      aliases: %{},
      ipsets: %{}
    }
  end
end
