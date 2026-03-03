# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Router do
  @moduledoc """
  HTTP router for the Mock PVE Server.

  Routes incoming requests to appropriate handlers and manages authentication,
  API versioning, and response formatting to match real PVE API behavior.
  """

  use Plug.Router
  require Logger

  alias MockPveApi.Handlers.{
    Version,
    Access,
    Nodes,
    Cluster,
    Pools,
    Storage,
    Metrics,
    Sdn,
    Snapshots,
    Firewall,
    Hardware,
    Notifications
  }

  alias MockPveApi.{State, Coverage}
  # alias MockPveApi.Capabilities  # Currently unused

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json, :urlencoded], json_decoder: Jason)
  plug(:authenticate)
  plug(:check_coverage_status)
  plug(:check_endpoint_support)
  plug(:track_endpoint_usage)
  plug(:add_cors_headers)
  plug(:dispatch)

  # Version endpoint (unauthenticated)
  get "/api2/json/version" do
    Version.get_version(conn)
  end

  # Access endpoints
  post "/api2/json/access/ticket" do
    Access.create_ticket(conn)
  end

  get "/api2/json/access/users" do
    Access.list_users(conn)
  end

  post "/api2/json/access/users" do
    Access.create_user(conn)
  end

  get "/api2/json/access/users/:userid" do
    Access.get_user(conn)
  end

  put "/api2/json/access/users/:userid" do
    Access.update_user(conn)
  end

  delete "/api2/json/access/users/:userid" do
    Access.delete_user(conn)
  end

  get "/api2/json/access/users/:userid/token" do
    Access.list_user_tokens(conn)
  end

  post "/api2/json/access/users/:userid/token/:tokenid" do
    Access.create_api_token(conn)
  end

  get "/api2/json/access/users/:userid/token/:tokenid" do
    Access.get_api_token(conn)
  end

  put "/api2/json/access/users/:userid/token/:tokenid" do
    Access.update_api_token(conn)
  end

  delete "/api2/json/access/users/:userid/token/:tokenid" do
    Access.delete_api_token(conn)
  end

  get "/api2/json/access/groups" do
    Access.list_groups(conn)
  end

  post "/api2/json/access/groups" do
    Access.create_group(conn)
  end

  get "/api2/json/access/groups/:groupid" do
    Access.get_group(conn)
  end

  put "/api2/json/access/groups/:groupid" do
    Access.update_group(conn)
  end

  delete "/api2/json/access/groups/:groupid" do
    Access.delete_group(conn)
  end

  get "/api2/json/access/domains" do
    Access.list_domains(conn)
  end

  post "/api2/json/access/domains" do
    Access.create_domain(conn)
  end

  get "/api2/json/access/domains/:realm" do
    Access.get_domain(conn)
  end

  put "/api2/json/access/domains/:realm" do
    Access.update_domain(conn)
  end

  delete "/api2/json/access/domains/:realm" do
    Access.delete_domain(conn)
  end

  get "/api2/json/access/permissions" do
    Access.get_permissions(conn)
  end

  get "/api2/json/access/acl" do
    Access.get_acl(conn)
  end

  put "/api2/json/access/acl" do
    Access.set_acl(conn)
  end

  get "/api2/json/access/roles" do
    Access.list_roles(conn)
  end

  post "/api2/json/access/roles" do
    Access.create_role(conn)
  end

  get "/api2/json/access/roles/:roleid" do
    Access.get_role(conn)
  end

  put "/api2/json/access/roles/:roleid" do
    Access.update_role(conn)
  end

  delete "/api2/json/access/roles/:roleid" do
    Access.delete_role(conn)
  end

  put "/api2/json/access/password" do
    Access.change_password(conn)
  end

  # TFA endpoints
  get "/api2/json/access/tfa" do
    Access.list_tfa(conn)
  end

  post "/api2/json/access/tfa" do
    Access.add_tfa(conn)
  end

  get "/api2/json/access/tfa/:userid" do
    Access.get_user_tfa(conn)
  end

  # Node endpoints
  get "/api2/json/nodes" do
    Nodes.list_nodes(conn)
  end

  get "/api2/json/nodes/:node" do
    Nodes.get_node(conn)
  end

  get "/api2/json/nodes/:node/status" do
    Nodes.get_node_status(conn)
  end

  get "/api2/json/nodes/:node/version" do
    Nodes.get_node_version(conn)
  end

  get "/api2/json/nodes/:node/config" do
    Nodes.get_node_config(conn)
  end

  put "/api2/json/nodes/:node/config" do
    Nodes.update_node_config(conn)
  end

  get "/api2/json/nodes/:node/dns" do
    Nodes.get_node_dns(conn)
  end

  put "/api2/json/nodes/:node/dns" do
    Nodes.update_node_dns(conn)
  end

  get "/api2/json/nodes/:node/apt/update" do
    Nodes.get_apt_updates(conn)
  end

  post "/api2/json/nodes/:node/apt/update" do
    Nodes.post_apt_update(conn)
  end

  get "/api2/json/nodes/:node/apt/versions" do
    Nodes.get_apt_versions(conn)
  end

  get "/api2/json/nodes/:node/network/:iface" do
    Nodes.get_node_network_iface(conn)
  end

  put "/api2/json/nodes/:node/network/:iface" do
    Nodes.update_node_network_iface(conn)
  end

  delete "/api2/json/nodes/:node/network/:iface" do
    Nodes.delete_node_network_iface(conn)
  end

  get "/api2/json/nodes/:node/disks/list" do
    Nodes.list_disks(conn)
  end

  get "/api2/json/nodes/:node/disks/lvm" do
    Nodes.list_disks_lvm(conn)
  end

  post "/api2/json/nodes/:node/disks/lvm" do
    Nodes.create_disk_lvm(conn)
  end

  get "/api2/json/nodes/:node/disks/lvmthin" do
    Nodes.list_disks_lvmthin(conn)
  end

  post "/api2/json/nodes/:node/disks/lvmthin" do
    Nodes.create_disk_lvmthin(conn)
  end

  get "/api2/json/nodes/:node/disks/zfs" do
    Nodes.list_disks_zfs(conn)
  end

  post "/api2/json/nodes/:node/disks/zfs" do
    Nodes.create_disk_zfs(conn)
  end

  post "/api2/json/nodes/:node/disks/initgpt" do
    Nodes.init_disk_gpt(conn)
  end

  # Node Ceph endpoints
  get "/api2/json/nodes/:node/ceph/status" do
    Nodes.get_node_ceph_status(conn)
  end

  get "/api2/json/nodes/:node/ceph/osd" do
    Nodes.list_node_ceph_osd(conn)
  end

  post "/api2/json/nodes/:node/ceph/osd" do
    Nodes.create_node_ceph_osd(conn)
  end

  get "/api2/json/nodes/:node/ceph/pools" do
    Nodes.list_node_ceph_pools(conn)
  end

  post "/api2/json/nodes/:node/ceph/pools" do
    Nodes.create_node_ceph_pool(conn)
  end

  # ACME certificate endpoints
  post "/api2/json/nodes/:node/certificates/acme/certificate" do
    Nodes.acme_certificate_new(conn)
  end

  put "/api2/json/nodes/:node/certificates/acme/certificate" do
    Nodes.acme_certificate_renew(conn)
  end

  delete "/api2/json/nodes/:node/certificates/acme/certificate" do
    Nodes.acme_certificate_delete(conn)
  end

  # Node firewall static endpoints
  get "/api2/json/nodes/:node/firewall/log" do
    Firewall.get_node_firewall_log(conn)
  end

  get "/api2/json/nodes/:node/firewall" do
    Firewall.get_node_firewall_index(conn)
  end

  # Node firewall endpoints
  get "/api2/json/nodes/:node/firewall/options" do
    Firewall.get_node_firewall_options(conn)
  end

  put "/api2/json/nodes/:node/firewall/options" do
    Firewall.update_node_firewall_options(conn)
  end

  get "/api2/json/nodes/:node/firewall/rules" do
    Firewall.list_node_firewall_rules(conn)
  end

  post "/api2/json/nodes/:node/firewall/rules" do
    Firewall.create_node_firewall_rule(conn)
  end

  get "/api2/json/nodes/:node/firewall/rules/:pos" do
    Firewall.get_node_firewall_rule(conn)
  end

  put "/api2/json/nodes/:node/firewall/rules/:pos" do
    Firewall.update_node_firewall_rule(conn)
  end

  delete "/api2/json/nodes/:node/firewall/rules/:pos" do
    Firewall.delete_node_firewall_rule(conn)
  end

  get "/api2/json/nodes/:node/tasks" do
    Nodes.get_node_tasks(conn)
  end

  get "/api2/json/nodes/:node/syslog" do
    Nodes.get_node_syslog(conn)
  end

  get "/api2/json/nodes/:node/network" do
    Nodes.get_node_network(conn)
  end

  post "/api2/json/nodes/:node/execute" do
    Nodes.execute_command(conn)
  end

  get "/api2/json/nodes/:node/vzdump/defaults" do
    Nodes.get_vzdump_defaults(conn)
  end

  get "/api2/json/nodes/:node/vzdump/extractconfig" do
    Nodes.get_vzdump_extractconfig(conn)
  end

  # Restore endpoints
  post "/api2/json/nodes/:node/qmrestore" do
    Nodes.qmrestore(conn)
  end

  post "/api2/json/nodes/:node/vzrestore" do
    Nodes.vzrestore(conn)
  end

  # Node hosts, subscription, bulk ops, journal, certificates, disks/smart
  get "/api2/json/nodes/:node/hosts" do
    Nodes.get_hosts(conn)
  end

  post "/api2/json/nodes/:node/hosts" do
    Nodes.set_hosts(conn)
  end

  get "/api2/json/nodes/:node/subscription" do
    Nodes.get_subscription(conn)
  end

  post "/api2/json/nodes/:node/subscription" do
    Nodes.set_subscription(conn)
  end

  post "/api2/json/nodes/:node/startall" do
    Nodes.startall(conn)
  end

  post "/api2/json/nodes/:node/stopall" do
    Nodes.stopall(conn)
  end

  post "/api2/json/nodes/:node/migrateall" do
    Nodes.migrateall(conn)
  end

  get "/api2/json/nodes/:node/journal" do
    Nodes.get_journal(conn)
  end

  get "/api2/json/nodes/:node/certificates/info" do
    Nodes.get_certificates_info(conn)
  end

  get "/api2/json/nodes/:node/disks/smart" do
    Nodes.get_disks_smart(conn)
  end

  # VM endpoints
  get "/api2/json/nodes/:node/qemu" do
    Nodes.list_vms(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid" do
    Nodes.get_vm(conn)
  end

  put "/api2/json/nodes/:node/qemu/:vmid" do
    Nodes.update_vm(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/config" do
    Nodes.get_vm_config(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/pending" do
    Nodes.get_vm_pending(conn)
  end

  put "/api2/json/nodes/:node/qemu/:vmid/resize" do
    Nodes.resize_vm_disk(conn)
  end

  # VM firewall endpoints
  get "/api2/json/nodes/:node/qemu/:vmid/firewall/options" do
    Firewall.get_vm_firewall_options(conn)
  end

  put "/api2/json/nodes/:node/qemu/:vmid/firewall/options" do
    Firewall.update_vm_firewall_options(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/firewall/rules/:pos" do
    Firewall.get_vm_firewall_rule(conn)
  end

  put "/api2/json/nodes/:node/qemu/:vmid/firewall/rules/:pos" do
    Firewall.update_vm_firewall_rule(conn)
  end

  delete "/api2/json/nodes/:node/qemu/:vmid/firewall/rules/:pos" do
    Firewall.delete_vm_firewall_rule(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/firewall/rules" do
    Firewall.list_vm_firewall_rules(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/firewall/rules" do
    Firewall.create_vm_firewall_rule(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/firewall/aliases/:name" do
    Firewall.get_vm_firewall_alias(conn)
  end

  put "/api2/json/nodes/:node/qemu/:vmid/firewall/aliases/:name" do
    Firewall.update_vm_firewall_alias(conn)
  end

  delete "/api2/json/nodes/:node/qemu/:vmid/firewall/aliases/:name" do
    Firewall.delete_vm_firewall_alias(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/firewall/aliases" do
    Firewall.list_vm_firewall_aliases(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/firewall/aliases" do
    Firewall.create_vm_firewall_alias(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/firewall/ipset/:name/:cidr" do
    Firewall.get_vm_firewall_ipset_entry(conn)
  end

  put "/api2/json/nodes/:node/qemu/:vmid/firewall/ipset/:name/:cidr" do
    Firewall.update_vm_firewall_ipset_entry(conn)
  end

  delete "/api2/json/nodes/:node/qemu/:vmid/firewall/ipset/:name/:cidr" do
    Firewall.delete_vm_firewall_ipset_entry(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/firewall/ipset/:name" do
    Firewall.get_vm_firewall_ipset(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/firewall/ipset/:name" do
    Firewall.add_vm_firewall_ipset_entry(conn)
  end

  delete "/api2/json/nodes/:node/qemu/:vmid/firewall/ipset/:name" do
    Firewall.delete_vm_firewall_ipset(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/firewall/ipset" do
    Firewall.list_vm_firewall_ipsets(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/firewall/ipset" do
    Firewall.create_vm_firewall_ipset(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/firewall/refs" do
    Firewall.get_vm_firewall_refs(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/firewall/log" do
    Firewall.get_vm_firewall_log(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/firewall" do
    Firewall.get_vm_firewall_index(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/status/current" do
    Nodes.get_vm_status(conn)
  end

  post "/api2/json/nodes/:node/qemu" do
    Nodes.create_vm(conn)
  end

  put "/api2/json/nodes/:node/qemu/:vmid/config" do
    Nodes.update_vm_config(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/status/:action" do
    Nodes.vm_action(conn)
  end

  delete "/api2/json/nodes/:node/qemu/:vmid" do
    Nodes.delete_vm(conn)
  end

  # Container endpoints
  get "/api2/json/nodes/:node/lxc" do
    Nodes.list_containers(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid" do
    Nodes.get_container(conn)
  end

  put "/api2/json/nodes/:node/lxc/:vmid" do
    Nodes.update_container(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/config" do
    Nodes.get_container_config(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/pending" do
    Nodes.get_container_pending(conn)
  end

  put "/api2/json/nodes/:node/lxc/:vmid/resize" do
    Nodes.resize_container_disk(conn)
  end

  # Container firewall endpoints
  get "/api2/json/nodes/:node/lxc/:vmid/firewall/options" do
    Firewall.get_ct_firewall_options(conn)
  end

  put "/api2/json/nodes/:node/lxc/:vmid/firewall/options" do
    Firewall.update_ct_firewall_options(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/firewall/rules/:pos" do
    Firewall.get_ct_firewall_rule(conn)
  end

  put "/api2/json/nodes/:node/lxc/:vmid/firewall/rules/:pos" do
    Firewall.update_ct_firewall_rule(conn)
  end

  delete "/api2/json/nodes/:node/lxc/:vmid/firewall/rules/:pos" do
    Firewall.delete_ct_firewall_rule(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/firewall/rules" do
    Firewall.list_ct_firewall_rules(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/firewall/rules" do
    Firewall.create_ct_firewall_rule(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/firewall/aliases/:name" do
    Firewall.get_ct_firewall_alias(conn)
  end

  put "/api2/json/nodes/:node/lxc/:vmid/firewall/aliases/:name" do
    Firewall.update_ct_firewall_alias(conn)
  end

  delete "/api2/json/nodes/:node/lxc/:vmid/firewall/aliases/:name" do
    Firewall.delete_ct_firewall_alias(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/firewall/aliases" do
    Firewall.list_ct_firewall_aliases(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/firewall/aliases" do
    Firewall.create_ct_firewall_alias(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/firewall/ipset/:name/:cidr" do
    Firewall.get_ct_firewall_ipset_entry(conn)
  end

  put "/api2/json/nodes/:node/lxc/:vmid/firewall/ipset/:name/:cidr" do
    Firewall.update_ct_firewall_ipset_entry(conn)
  end

  delete "/api2/json/nodes/:node/lxc/:vmid/firewall/ipset/:name/:cidr" do
    Firewall.delete_ct_firewall_ipset_entry(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/firewall/ipset/:name" do
    Firewall.get_ct_firewall_ipset(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/firewall/ipset/:name" do
    Firewall.add_ct_firewall_ipset_entry(conn)
  end

  delete "/api2/json/nodes/:node/lxc/:vmid/firewall/ipset/:name" do
    Firewall.delete_ct_firewall_ipset(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/firewall/ipset" do
    Firewall.list_ct_firewall_ipsets(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/firewall/ipset" do
    Firewall.create_ct_firewall_ipset(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/firewall/refs" do
    Firewall.get_ct_firewall_refs(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/firewall/log" do
    Firewall.get_ct_firewall_log(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/firewall" do
    Firewall.get_ct_firewall_index(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/status/current" do
    Nodes.get_container_status(conn)
  end

  post "/api2/json/nodes/:node/lxc" do
    Nodes.create_container(conn)
  end

  put "/api2/json/nodes/:node/lxc/:vmid/config" do
    Nodes.update_container_config(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/status/:action" do
    Nodes.container_action(conn)
  end

  delete "/api2/json/nodes/:node/lxc/:vmid" do
    Nodes.delete_container(conn)
  end

  # VM/Container migration, backup and snapshot endpoints
  post "/api2/json/nodes/:node/qemu/:vmid/migrate" do
    Nodes.migrate_vm(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/migrate" do
    Nodes.migrate_container(conn)
  end

  # VM snapshot endpoints
  get "/api2/json/nodes/:node/qemu/:vmid/snapshot" do
    Snapshots.list_snapshots(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/snapshot" do
    Snapshots.create_snapshot(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/snapshot/:snapname" do
    Snapshots.get_snapshot(conn)
  end

  delete "/api2/json/nodes/:node/qemu/:vmid/snapshot/:snapname" do
    Snapshots.delete_snapshot(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/snapshot/:snapname/config" do
    Snapshots.get_snapshot_config(conn)
  end

  put "/api2/json/nodes/:node/qemu/:vmid/snapshot/:snapname/config" do
    Snapshots.update_snapshot_config(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/snapshot/:snapname/rollback" do
    Snapshots.rollback_snapshot(conn)
  end

  # Container snapshot endpoints
  get "/api2/json/nodes/:node/lxc/:vmid/snapshot" do
    Snapshots.list_snapshots(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/snapshot" do
    Snapshots.create_snapshot(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/snapshot/:snapname" do
    Snapshots.get_snapshot(conn)
  end

  delete "/api2/json/nodes/:node/lxc/:vmid/snapshot/:snapname" do
    Snapshots.delete_snapshot(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/snapshot/:snapname/config" do
    Snapshots.get_snapshot_config(conn)
  end

  put "/api2/json/nodes/:node/lxc/:vmid/snapshot/:snapname/config" do
    Snapshots.update_snapshot_config(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/snapshot/:snapname/rollback" do
    Snapshots.rollback_snapshot(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/clone" do
    Nodes.clone_vm(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/feature" do
    Nodes.get_vm_feature(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/template" do
    Nodes.convert_vm_to_template(conn)
  end

  put "/api2/json/nodes/:node/qemu/:vmid/sendkey" do
    Nodes.vm_sendkey(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/agent" do
    Nodes.vm_agent(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/cloudinit/dump" do
    Nodes.get_vm_cloudinit_dump(conn)
  end

  put "/api2/json/nodes/:node/qemu/:vmid/unlink" do
    Nodes.vm_unlink(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/move_disk" do
    Nodes.vm_move_disk(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/clone" do
    Nodes.clone_container(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/feature" do
    Nodes.get_ct_feature(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/template" do
    Nodes.convert_ct_to_template(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/move_volume" do
    Nodes.ct_move_volume(conn)
  end

  post "/api2/json/nodes/:node/vzdump" do
    Nodes.create_backup(conn)
  end

  get "/api2/json/nodes/:node/storage/:storage/backup" do
    Nodes.list_backup_files(conn)
  end

  # Task endpoints with progress
  get "/api2/json/nodes/:node/tasks/:upid/status" do
    Nodes.get_task_status(conn)
  end

  get "/api2/json/nodes/:node/tasks/:upid/log" do
    Nodes.get_task_log(conn)
  end

  delete "/api2/json/nodes/:node/tasks/:upid" do
    Nodes.delete_task(conn)
  end

  get "/api2/json/nodes/:node/time" do
    Nodes.get_node_time(conn)
  end

  put "/api2/json/nodes/:node/time" do
    Nodes.set_node_time(conn)
  end

  # Node hardware detection endpoints
  get "/api2/json/nodes/:node/hardware/pci/:pciid" do
    Hardware.get_pci(conn)
  end

  get "/api2/json/nodes/:node/hardware/pci" do
    Hardware.list_pci(conn)
  end

  get "/api2/json/nodes/:node/hardware/usb" do
    Hardware.list_usb(conn)
  end

  # Metrics and statistics endpoints
  get "/api2/json/nodes/:node/rrd" do
    Metrics.get_node_rrd(conn)
  end

  get "/api2/json/nodes/:node/rrddata" do
    Metrics.get_node_rrd_data(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/rrddata" do
    Metrics.get_vm_rrd_data(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/rrd" do
    Metrics.get_vm_rrd(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/rrddata" do
    Metrics.get_container_rrd_data(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/rrd" do
    Metrics.get_container_rrd(conn)
  end

  get "/api2/json/nodes/:node/netstat" do
    Metrics.get_node_netstat(conn)
  end

  get "/api2/json/nodes/:node/report" do
    Metrics.get_node_report(conn)
  end

  get "/api2/json/cluster/metrics/server/:id" do
    Metrics.get_cluster_metrics(conn)
  end

  get "/api2/json/cluster/metrics/server" do
    Metrics.list_metrics_servers(conn)
  end

  get "/api2/json/cluster/metrics" do
    Metrics.get_metrics_index(conn)
  end

  # Node services endpoints
  get "/api2/json/nodes/:node/services/:service/state" do
    Metrics.get_service(conn)
  end

  put "/api2/json/nodes/:node/services/:service/state" do
    Metrics.set_service_state(conn)
  end

  get "/api2/json/nodes/:node/services/:service" do
    Metrics.get_service(conn)
  end

  get "/api2/json/nodes/:node/services" do
    Metrics.list_services(conn)
  end

  # Storage endpoints
  get "/api2/json/storage" do
    Storage.list_storage(conn)
  end

  post "/api2/json/storage" do
    Storage.create_storage(conn)
  end

  get "/api2/json/storage/:storage" do
    Storage.get_storage(conn)
  end

  put "/api2/json/storage/:storage" do
    Storage.update_storage(conn)
  end

  delete "/api2/json/storage/:storage" do
    Storage.delete_storage(conn)
  end

  # Storage file-restore endpoints
  get "/api2/json/nodes/:node/storage/:storage/file-restore/list" do
    Storage.list_file_restore(conn)
  end

  get "/api2/json/nodes/:node/storage/:storage/file-restore/download" do
    Storage.download_file_restore(conn)
  end

  # Storage prunebackups
  get "/api2/json/nodes/:node/storage/:storage/prunebackups" do
    Storage.list_prunebackups(conn)
  end

  delete "/api2/json/nodes/:node/storage/:storage/prunebackups" do
    Storage.delete_prunebackups(conn)
  end

  get "/api2/json/nodes/:node/storage/:storage/status" do
    Storage.get_storage_status(conn)
  end

  get "/api2/json/nodes/:node/storage/:storage/rrd" do
    Metrics.get_storage_rrd(conn)
  end

  get "/api2/json/nodes/:node/storage/:storage/rrddata" do
    Metrics.get_storage_rrd_data(conn)
  end

  get "/api2/json/nodes/:node/storage/:storage/content/:volume" do
    Storage.get_storage_volume(conn)
  end

  delete "/api2/json/nodes/:node/storage/:storage/content/:volume" do
    Storage.delete_storage_volume(conn)
  end

  get "/api2/json/nodes/:node/storage/:storage/content" do
    Storage.get_storage_content(conn)
  end

  post "/api2/json/nodes/:node/storage/:storage/content" do
    Storage.create_storage_content(conn)
  end

  post "/api2/json/nodes/:node/storage/:storage/upload" do
    Storage.upload_storage_content(conn)
  end

  # Cluster endpoints  
  get "/api2/json/cluster/status" do
    Cluster.get_cluster_status(conn)
  end

  get "/api2/json/cluster/resources" do
    Cluster.get_resources(conn)
  end

  get "/api2/json/cluster/nextid" do
    Cluster.get_next_vmid(conn)
  end

  get "/api2/json/cluster/config" do
    Cluster.get_cluster_config(conn)
  end

  put "/api2/json/cluster/config" do
    Cluster.update_cluster_config(conn)
  end

  post "/api2/json/cluster/config/join" do
    Cluster.join_cluster(conn)
  end

  get "/api2/json/cluster/config/nodes" do
    Cluster.get_cluster_nodes_config(conn)
  end

  delete "/api2/json/cluster/config/nodes/:node" do
    Cluster.remove_cluster_node(conn)
  end

  # Backup providers (PVE 8.2+)
  get "/api2/json/cluster/backup-info/providers" do
    Cluster.list_backup_providers(conn)
  end

  # HA resource endpoints
  get "/api2/json/cluster/ha/resources" do
    Cluster.list_ha_resources(conn)
  end

  post "/api2/json/cluster/ha/resources" do
    Cluster.create_ha_resource(conn)
  end

  get "/api2/json/cluster/ha/resources/:sid" do
    Cluster.get_ha_resource(conn)
  end

  put "/api2/json/cluster/ha/resources/:sid" do
    Cluster.update_ha_resource(conn)
  end

  delete "/api2/json/cluster/ha/resources/:sid" do
    Cluster.delete_ha_resource(conn)
  end

  # HA status
  get "/api2/json/cluster/ha/status/current" do
    Cluster.get_ha_status(conn)
  end

  # HA group endpoints
  get "/api2/json/cluster/ha/groups" do
    Cluster.list_ha_groups(conn)
  end

  post "/api2/json/cluster/ha/groups" do
    Cluster.create_ha_group(conn)
  end

  get "/api2/json/cluster/ha/groups/:group" do
    Cluster.get_ha_group(conn)
  end

  put "/api2/json/cluster/ha/groups/:group" do
    Cluster.update_ha_group(conn)
  end

  delete "/api2/json/cluster/ha/groups/:group" do
    Cluster.delete_ha_group(conn)
  end

  # HA affinity rules (PVE 9.0+)
  get "/api2/json/cluster/ha/affinity" do
    Cluster.list_ha_affinity_rules(conn)
  end

  post "/api2/json/cluster/ha/affinity" do
    Cluster.create_ha_affinity_rule(conn)
  end

  get "/api2/json/cluster/ha/affinity/:rule" do
    Cluster.get_ha_affinity_rule(conn)
  end

  put "/api2/json/cluster/ha/affinity/:rule" do
    Cluster.update_ha_affinity_rule(conn)
  end

  delete "/api2/json/cluster/ha/affinity/:rule" do
    Cluster.delete_ha_affinity_rule(conn)
  end

  # Cluster resource mapping endpoints (PCI/USB passthrough)
  get "/api2/json/cluster/mapping/pci" do
    Hardware.list_pci_mappings(conn)
  end

  post "/api2/json/cluster/mapping/pci" do
    Hardware.create_pci_mapping(conn)
  end

  get "/api2/json/cluster/mapping/pci/:id" do
    Hardware.get_pci_mapping(conn)
  end

  put "/api2/json/cluster/mapping/pci/:id" do
    Hardware.update_pci_mapping(conn)
  end

  delete "/api2/json/cluster/mapping/pci/:id" do
    Hardware.delete_pci_mapping(conn)
  end

  get "/api2/json/cluster/mapping/usb" do
    Hardware.list_usb_mappings(conn)
  end

  post "/api2/json/cluster/mapping/usb" do
    Hardware.create_usb_mapping(conn)
  end

  get "/api2/json/cluster/mapping/usb/:id" do
    Hardware.get_usb_mapping(conn)
  end

  put "/api2/json/cluster/mapping/usb/:id" do
    Hardware.update_usb_mapping(conn)
  end

  delete "/api2/json/cluster/mapping/usb/:id" do
    Hardware.delete_usb_mapping(conn)
  end

  # Backup job endpoints
  get "/api2/json/cluster/backup" do
    Cluster.list_backup_jobs(conn)
  end

  post "/api2/json/cluster/backup" do
    Cluster.create_backup_job(conn)
  end

  get "/api2/json/cluster/backup/:id/included_volumes" do
    Cluster.get_backup_job_volumes(conn)
  end

  get "/api2/json/cluster/backup/:id" do
    Cluster.get_backup_job(conn)
  end

  put "/api2/json/cluster/backup/:id" do
    Cluster.update_backup_job(conn)
  end

  delete "/api2/json/cluster/backup/:id" do
    Cluster.delete_backup_job(conn)
  end

  # Backup info
  get "/api2/json/cluster/backup-info/not-backed-up" do
    Cluster.get_not_backed_up(conn)
  end

  # Replication
  get "/api2/json/cluster/replication" do
    Cluster.list_replication_jobs(conn)
  end

  post "/api2/json/cluster/replication" do
    Cluster.create_replication_job(conn)
  end

  get "/api2/json/cluster/replication/:id" do
    Cluster.get_replication_job(conn)
  end

  put "/api2/json/cluster/replication/:id" do
    Cluster.update_replication_job(conn)
  end

  delete "/api2/json/cluster/replication/:id" do
    Cluster.delete_replication_job(conn)
  end

  # Cluster Ceph endpoints
  get "/api2/json/cluster/ceph/flags" do
    Cluster.get_ceph_flags(conn)
  end

  put "/api2/json/cluster/ceph/flags" do
    Cluster.set_ceph_flags(conn)
  end

  get "/api2/json/cluster/ceph/metadata" do
    Cluster.get_ceph_metadata(conn)
  end

  get "/api2/json/cluster/ceph/status" do
    Cluster.get_ceph_status(conn)
  end

  # Cluster ACME endpoints
  get "/api2/json/cluster/acme/account" do
    Cluster.list_acme_accounts(conn)
  end

  post "/api2/json/cluster/acme/account" do
    Cluster.create_acme_account(conn)
  end

  get "/api2/json/cluster/acme/plugins" do
    Cluster.list_acme_plugins(conn)
  end

  post "/api2/json/cluster/acme/plugins" do
    Cluster.create_acme_plugin(conn)
  end

  # Cluster firewall static endpoints
  get "/api2/json/cluster/firewall/refs" do
    Firewall.get_cluster_firewall_refs(conn)
  end

  get "/api2/json/cluster/firewall/macros" do
    Firewall.get_cluster_firewall_macros(conn)
  end

  get "/api2/json/cluster/firewall/log" do
    Firewall.get_cluster_firewall_log(conn)
  end

  # Cluster firewall endpoints
  get "/api2/json/cluster/firewall/options" do
    Firewall.get_cluster_firewall_options(conn)
  end

  put "/api2/json/cluster/firewall/options" do
    Firewall.update_cluster_firewall_options(conn)
  end

  get "/api2/json/cluster/firewall/rules" do
    Firewall.list_cluster_firewall_rules(conn)
  end

  post "/api2/json/cluster/firewall/rules" do
    Firewall.create_cluster_firewall_rule(conn)
  end

  get "/api2/json/cluster/firewall/rules/:pos" do
    Firewall.get_cluster_firewall_rule(conn)
  end

  put "/api2/json/cluster/firewall/rules/:pos" do
    Firewall.update_cluster_firewall_rule(conn)
  end

  delete "/api2/json/cluster/firewall/rules/:pos" do
    Firewall.delete_cluster_firewall_rule(conn)
  end

  get "/api2/json/cluster/firewall/groups" do
    Firewall.list_security_groups(conn)
  end

  post "/api2/json/cluster/firewall/groups" do
    Firewall.create_security_group(conn)
  end

  get "/api2/json/cluster/firewall/groups/:group/:pos" do
    Firewall.get_security_group_rule(conn)
  end

  put "/api2/json/cluster/firewall/groups/:group/:pos" do
    Firewall.update_security_group_rule(conn)
  end

  delete "/api2/json/cluster/firewall/groups/:group/:pos" do
    Firewall.delete_security_group_rule(conn)
  end

  get "/api2/json/cluster/firewall/groups/:group" do
    Firewall.get_security_group(conn)
  end

  delete "/api2/json/cluster/firewall/groups/:group" do
    Firewall.delete_security_group(conn)
  end

  get "/api2/json/cluster/firewall/aliases" do
    Firewall.list_aliases(conn)
  end

  post "/api2/json/cluster/firewall/aliases" do
    Firewall.create_alias(conn)
  end

  get "/api2/json/cluster/firewall/aliases/:name" do
    Firewall.get_alias(conn)
  end

  put "/api2/json/cluster/firewall/aliases/:name" do
    Firewall.update_alias(conn)
  end

  delete "/api2/json/cluster/firewall/aliases/:name" do
    Firewall.delete_alias(conn)
  end

  get "/api2/json/cluster/firewall/ipset" do
    Firewall.list_ipsets(conn)
  end

  post "/api2/json/cluster/firewall/ipset" do
    Firewall.create_ipset(conn)
  end

  get "/api2/json/cluster/firewall/ipset/:name/:cidr" do
    Firewall.get_ipset_entry(conn)
  end

  put "/api2/json/cluster/firewall/ipset/:name/:cidr" do
    Firewall.update_ipset_entry(conn)
  end

  delete "/api2/json/cluster/firewall/ipset/:name/:cidr" do
    Firewall.delete_ipset_entry(conn)
  end

  get "/api2/json/cluster/firewall/ipset/:name" do
    Firewall.get_ipset(conn)
  end

  post "/api2/json/cluster/firewall/ipset/:name" do
    Firewall.add_ipset_entry(conn)
  end

  delete "/api2/json/cluster/firewall/ipset/:name" do
    Firewall.delete_ipset(conn)
  end

  # Cluster options
  get "/api2/json/cluster/options" do
    Cluster.get_cluster_options(conn)
  end

  put "/api2/json/cluster/options" do
    Cluster.update_cluster_options(conn)
  end

  # Pool endpoints
  get "/api2/json/pools" do
    Pools.list_pools(conn)
  end

  get "/api2/json/pools/:poolid" do
    Pools.get_pool(conn)
  end

  post "/api2/json/pools" do
    Pools.create_pool(conn)
  end

  put "/api2/json/pools/:poolid" do
    Pools.update_pool(conn)
  end

  delete "/api2/json/pools/:poolid" do
    Pools.delete_pool(conn)
  end

  # SDN endpoints (PVE 8.0+ only)
  get "/api2/json/cluster/sdn" do
    Sdn.get_sdn_index(conn)
  end

  get "/api2/json/cluster/sdn/zones" do
    Sdn.list_zones(conn)
  end

  post "/api2/json/cluster/sdn/zones" do
    Sdn.create_zone(conn)
  end

  get "/api2/json/cluster/sdn/zones/:zone" do
    Sdn.get_zone(conn)
  end

  put "/api2/json/cluster/sdn/zones/:zone" do
    Sdn.update_zone(conn)
  end

  delete "/api2/json/cluster/sdn/zones/:zone" do
    Sdn.delete_zone(conn)
  end

  get "/api2/json/cluster/sdn/vnets" do
    Sdn.list_vnets(conn)
  end

  post "/api2/json/cluster/sdn/vnets" do
    Sdn.create_vnet(conn)
  end

  get "/api2/json/cluster/sdn/vnets/:vnet/subnets" do
    Sdn.list_subnets(conn)
  end

  post "/api2/json/cluster/sdn/vnets/:vnet/subnets" do
    Sdn.create_subnet(conn)
  end

  get "/api2/json/cluster/sdn/vnets/:vnet/subnets/:subnet" do
    Sdn.get_subnet(conn)
  end

  put "/api2/json/cluster/sdn/vnets/:vnet/subnets/:subnet" do
    Sdn.update_subnet(conn)
  end

  delete "/api2/json/cluster/sdn/vnets/:vnet/subnets/:subnet" do
    Sdn.delete_subnet(conn)
  end

  get "/api2/json/cluster/sdn/vnets/:vnet" do
    Sdn.get_vnet(conn)
  end

  put "/api2/json/cluster/sdn/vnets/:vnet" do
    Sdn.update_vnet(conn)
  end

  delete "/api2/json/cluster/sdn/vnets/:vnet" do
    Sdn.delete_vnet(conn)
  end

  get "/api2/json/cluster/sdn/controllers" do
    Sdn.list_controllers(conn)
  end

  post "/api2/json/cluster/sdn/controllers" do
    Sdn.create_controller(conn)
  end

  get "/api2/json/cluster/sdn/controllers/:controller" do
    Sdn.get_controller(conn)
  end

  put "/api2/json/cluster/sdn/controllers/:controller" do
    Sdn.update_controller(conn)
  end

  delete "/api2/json/cluster/sdn/controllers/:controller" do
    Sdn.delete_controller(conn)
  end

  # SDN DNS endpoints
  get "/api2/json/cluster/sdn/dns" do
    Sdn.list_dns(conn)
  end

  post "/api2/json/cluster/sdn/dns" do
    Sdn.create_dns(conn)
  end

  get "/api2/json/cluster/sdn/dns/:dns" do
    Sdn.get_dns(conn)
  end

  put "/api2/json/cluster/sdn/dns/:dns" do
    Sdn.update_dns(conn)
  end

  delete "/api2/json/cluster/sdn/dns/:dns" do
    Sdn.delete_dns(conn)
  end

  # SDN IPAM endpoints
  get "/api2/json/cluster/sdn/ipams" do
    Sdn.list_ipams(conn)
  end

  post "/api2/json/cluster/sdn/ipams" do
    Sdn.create_ipam(conn)
  end

  get "/api2/json/cluster/sdn/ipams/:ipam" do
    Sdn.get_ipam(conn)
  end

  put "/api2/json/cluster/sdn/ipams/:ipam" do
    Sdn.update_ipam(conn)
  end

  delete "/api2/json/cluster/sdn/ipams/:ipam" do
    Sdn.delete_ipam(conn)
  end

  # Realm sync endpoints (PVE 8.0+ only)
  post "/api2/json/access/domains/:realm/sync" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: "sync-task-upid"}))
  end

  # Notification endpoints (PVE 8.1+ only)
  get "/api2/json/cluster/notifications/endpoints/gotify/:name" do
    Notifications.get_gotify(conn)
  end

  put "/api2/json/cluster/notifications/endpoints/gotify/:name" do
    Notifications.update_gotify(conn)
  end

  delete "/api2/json/cluster/notifications/endpoints/gotify/:name" do
    Notifications.delete_gotify(conn)
  end

  get "/api2/json/cluster/notifications/endpoints/gotify" do
    Notifications.list_gotify(conn)
  end

  post "/api2/json/cluster/notifications/endpoints/gotify" do
    Notifications.create_gotify(conn)
  end

  get "/api2/json/cluster/notifications/endpoints/sendmail/:name" do
    Notifications.get_sendmail(conn)
  end

  put "/api2/json/cluster/notifications/endpoints/sendmail/:name" do
    Notifications.update_sendmail(conn)
  end

  delete "/api2/json/cluster/notifications/endpoints/sendmail/:name" do
    Notifications.delete_sendmail(conn)
  end

  get "/api2/json/cluster/notifications/endpoints/sendmail" do
    Notifications.list_sendmail(conn)
  end

  post "/api2/json/cluster/notifications/endpoints/sendmail" do
    Notifications.create_sendmail(conn)
  end

  get "/api2/json/cluster/notifications/matchers/:name" do
    Notifications.get_matcher(conn)
  end

  put "/api2/json/cluster/notifications/matchers/:name" do
    Notifications.update_matcher(conn)
  end

  delete "/api2/json/cluster/notifications/matchers/:name" do
    Notifications.delete_matcher(conn)
  end

  get "/api2/json/cluster/notifications/matchers" do
    Notifications.list_matchers(conn)
  end

  post "/api2/json/cluster/notifications/matchers" do
    Notifications.create_matcher(conn)
  end

  get "/api2/json/cluster/notifications/endpoints" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  get "/api2/json/cluster/notifications/filters" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  # VMware import endpoints (PVE 8.2+ only)
  post "/api2/json/nodes/:node/storage/:storage/import" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: "import-task-upid"}))
  end

  # Backup provider endpoints (PVE 8.2+ only)
  get "/api2/json/cluster/backup-providers" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  # Coverage API endpoints
  get "/api2/json/_coverage/stats" do
    stats = Coverage.get_coverage_stats()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: stats}))
  end

  get "/api2/json/_coverage/categories" do
    category_stats = Coverage.get_category_stats()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: category_stats}))
  end

  get "/api2/json/_coverage/missing" do
    missing = Coverage.get_missing_critical_endpoints()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: missing}))
  end

  # Catch all for unimplemented endpoints
  match _ do
    endpoint_path = conn.request_path
    method = String.downcase(conn.method) |> String.to_atom()

    case Coverage.get_endpoint_info(endpoint_path) do
      nil ->
        Logger.warning("Unknown endpoint: #{conn.method} #{endpoint_path}")
        send_unknown_endpoint_error(conn, endpoint_path)

      endpoint_info ->
        case endpoint_info.status do
          :not_supported ->
            Logger.info("Endpoint not supported: #{endpoint_path}")
            send_not_supported_error(conn, endpoint_info)

          :planned ->
            Logger.info("Endpoint planned but not implemented: #{endpoint_path}")
            send_planned_error(conn, endpoint_info)

          _ ->
            if method in endpoint_info.methods do
              Logger.warning("Endpoint matched but handler missing: #{endpoint_path}")
              send_handler_missing_error(conn, endpoint_info)
            else
              Logger.warning("Method not allowed: #{conn.method} #{endpoint_path}")
              send_method_not_allowed_error(conn, endpoint_info)
            end
        end
    end
  end

  # Endpoint support checking plug
  defp check_endpoint_support(%Plug.Conn{request_path: "/api2/json/version"} = conn, _opts) do
    # Version endpoint is always supported
    conn
  end

  defp check_endpoint_support(conn, _opts) do
    if State.endpoint_supported?(conn.request_path) do
      conn
    else
      Logger.warning("Endpoint not supported in current PVE version: #{conn.request_path}")

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        501,
        Jason.encode!(%{
          "errors" => %{
            "message" =>
              "Feature not available in PVE version #{State.get_pve_version()}: #{conn.request_path}"
          }
        })
      )
      |> halt()
    end
  end

  # Authentication plug
  defp authenticate(%Plug.Conn{request_path: "/api2/json/version"} = conn, _opts) do
    # Version endpoint doesn't require authentication
    conn
  end

  defp authenticate(%Plug.Conn{request_path: "/api2/json/access/ticket"} = conn, _opts) do
    # Ticket creation endpoint doesn't require authentication
    conn
  end

  defp authenticate(conn, _opts) do
    case get_auth_header(conn) do
      {:ok, _auth_type, _token} ->
        # In a real implementation, we'd validate the token/ticket
        # For mocking purposes, we just check that auth is present
        conn

      {:error, :missing} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          401,
          Jason.encode!(%{
            "errors" => %{
              "message" => "authentication failure"
            }
          })
        )
        |> halt()
    end
  end

  defp get_auth_header(conn) do
    # Check Authorization header first
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        {:ok, :token, token}

      ["PVEAuthCookie=" <> ticket] ->
        {:ok, :ticket, ticket}

      ["PVEAPIToken=" <> token] ->
        {:ok, :api_token, token}

      [] ->
        # Check cookies if no Authorization header
        case get_req_header(conn, "cookie") do
          [cookie_header] ->
            # Parse cookies to find PVEAuthCookie
            case parse_cookies(cookie_header) do
              %{"PVEAuthCookie" => ticket} -> {:ok, :ticket, ticket}
              _ -> {:error, :missing}
            end

          [] ->
            {:error, :missing}
        end

      _ ->
        {:error, :missing}
    end
  end

  defp parse_cookies(cookie_header) do
    cookie_header
    |> String.split(";")
    |> Enum.map(&String.trim/1)
    |> Enum.reduce(%{}, fn cookie, acc ->
      case String.split(cookie, "=", parts: 2) do
        [key, value] -> Map.put(acc, String.trim(key), String.trim(value))
        _ -> acc
      end
    end)
  end

  # Coverage status checking plug
  defp check_coverage_status(%Plug.Conn{request_path: "/api2/json/version"} = conn, _opts) do
    # Version endpoint always passes
    conn
  end

  defp check_coverage_status(%Plug.Conn{request_path: "/api2/json/_coverage" <> _} = conn, _opts) do
    # Coverage API endpoints always pass
    conn
  end

  defp check_coverage_status(conn, _opts) do
    endpoint_path = conn.request_path
    method = String.downcase(conn.method) |> String.to_atom()

    case Coverage.get_endpoint_info(endpoint_path) do
      nil ->
        # Unknown endpoint, let catch-all handle it
        conn

      endpoint_info ->
        case {endpoint_info.status, method in endpoint_info.methods} do
          {:not_supported, _} ->
            send_not_supported_error(conn, endpoint_info) |> halt()

          {_, false} ->
            send_method_not_allowed_error(conn, endpoint_info) |> halt()

          _ ->
            conn
        end
    end
  end

  # Endpoint usage tracking plug
  defp track_endpoint_usage(%Plug.Conn{request_path: "/api2/json/_coverage" <> _} = conn, _opts) do
    # Don't track coverage API calls
    conn
  end

  defp track_endpoint_usage(conn, _opts) do
    # Track endpoint usage for metrics
    endpoint_path = conn.request_path
    method = String.downcase(conn.method) |> String.to_atom()

    case Coverage.get_endpoint_info(endpoint_path) do
      nil ->
        conn

      endpoint_info ->
        Logger.debug("API call: #{method} #{endpoint_path} (status: #{endpoint_info.status})")
        # TODO: Add metrics collection here
        conn
    end
  end

  # Error response helpers
  defp send_unknown_endpoint_error(conn, endpoint_path) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      404,
      Jason.encode!(%{
        errors: ["Unknown endpoint: #{endpoint_path}"],
        coverage_info: "Endpoint not found in coverage matrix"
      })
    )
  end

  defp send_not_supported_error(conn, endpoint_info) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      501,
      Jason.encode!(%{
        errors: ["Endpoint not supported: #{endpoint_info.path}"],
        coverage_info: %{
          status: endpoint_info.status,
          description: endpoint_info.description,
          notes: endpoint_info.notes
        }
      })
    )
  end

  defp send_planned_error(conn, endpoint_info) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      501,
      Jason.encode!(%{
        errors: ["Endpoint planned but not yet implemented: #{endpoint_info.path}"],
        coverage_info: %{
          status: endpoint_info.status,
          priority: endpoint_info.priority,
          description: endpoint_info.description,
          notes: endpoint_info.notes
        }
      })
    )
  end

  defp send_handler_missing_error(conn, endpoint_info) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      500,
      Jason.encode!(%{
        errors: ["Handler module missing for implemented endpoint: #{endpoint_info.path}"],
        coverage_info: %{
          expected_handler: endpoint_info.handler_module,
          status: endpoint_info.status
        }
      })
    )
  end

  defp send_method_not_allowed_error(conn, endpoint_info) do
    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header("allow", Enum.join(endpoint_info.methods, ", ") |> String.upcase())
    |> send_resp(
      405,
      Jason.encode!(%{
        errors: ["Method not allowed: #{String.upcase(conn.method)}"],
        coverage_info: %{
          allowed_methods: endpoint_info.methods,
          endpoint: endpoint_info.path
        }
      })
    )
  end

  defp add_cors_headers(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "authorization, content-type")
  end
end
