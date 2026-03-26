# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.StateTest do
  use ExUnit.Case, async: false

  alias MockPveApi.State

  setup do
    State.reset()
    :ok
  end

  # --- Node operations ---

  describe "get_nodes/0" do
    test "returns initial nodes" do
      nodes = State.get_nodes()
      assert length(nodes) == 2
      names = Enum.map(nodes, & &1.node)
      assert "pve-node1" in names
      assert "pve-node2" in names
    end
  end

  describe "get_node/1" do
    test "returns node by name" do
      node = State.get_node("pve-node1")
      assert node.node == "pve-node1"
      assert node.status == "online"
    end

    test "returns nil for unknown node" do
      assert State.get_node("nonexistent") == nil
    end
  end

  describe "update_node/2" do
    test "updates node attributes" do
      State.update_node("pve-node1", %{cpu: 0.99})
      # cast is async, give it a moment
      :timer.sleep(10)
      node = State.get_node("pve-node1")
      assert node.cpu == 0.99
    end

    test "ignores update for unknown node" do
      State.update_node("nonexistent", %{cpu: 0.5})
      :timer.sleep(10)
      assert State.get_node("nonexistent") == nil
    end
  end

  # --- VM operations ---

  describe "create_vm/3" do
    test "creates a VM" do
      assert {:ok, vm} = State.create_vm("pve-node1", 100, %{name: "test-vm"})
      assert vm.vmid == 100
      assert vm.node == "pve-node1"
      assert vm.name == "test-vm"
      assert vm.status == "stopped"
    end

    test "returns error for duplicate vmid" do
      {:ok, _} = State.create_vm("pve-node1", 100, %{})
      assert {:error, "VM 100 already exists"} = State.create_vm("pve-node1", 100, %{})
    end

    test "uses default values when config is empty" do
      {:ok, vm} = State.create_vm("pve-node1", 101, %{})
      assert vm.memory == 2048
      assert vm.cores == 2
      assert vm.sockets == 1
      assert vm.ostype == "l26"
    end
  end

  describe "get_vms/1" do
    test "returns empty list initially" do
      assert State.get_vms("pve-node1") == []
    end

    test "returns VMs for specific node" do
      State.create_vm("pve-node1", 100, %{})
      State.create_vm("pve-node2", 101, %{})

      vms = State.get_vms("pve-node1")
      assert length(vms) == 1
      assert hd(vms).vmid == 100
    end

    test "returns all VMs when node is nil" do
      State.create_vm("pve-node1", 100, %{})
      State.create_vm("pve-node2", 101, %{})

      assert length(State.get_vms(nil)) == 2
    end
  end

  describe "get_vm/2" do
    test "returns VM on correct node" do
      State.create_vm("pve-node1", 100, %{})
      assert %{vmid: 100} = State.get_vm("pve-node1", 100)
    end

    test "returns nil when VM is on different node" do
      State.create_vm("pve-node1", 100, %{})
      assert State.get_vm("pve-node2", 100) == nil
    end

    test "returns nil for nonexistent VM" do
      assert State.get_vm("pve-node1", 999) == nil
    end
  end

  describe "update_vm/3" do
    test "updates VM config" do
      State.create_vm("pve-node1", 100, %{})
      assert {:ok, vm} = State.update_vm("pve-node1", 100, %{memory: 4096})
      assert vm.memory == 4096
    end

    test "returns error for nonexistent VM" do
      assert {:error, "VM 999 not found"} = State.update_vm("pve-node1", 999, %{})
    end

    test "returns error when VM is on different node" do
      State.create_vm("pve-node1", 100, %{})
      assert {:error, _} = State.update_vm("pve-node2", 100, %{})
    end
  end

  describe "delete_vm/2" do
    test "deletes a VM" do
      State.create_vm("pve-node1", 100, %{})
      State.delete_vm("pve-node1", 100)
      :timer.sleep(10)
      assert State.get_vm("pve-node1", 100) == nil
    end

    test "ignores delete for nonexistent VM" do
      State.delete_vm("pve-node1", 999)
      :timer.sleep(10)
      # no crash
    end

    test "ignores delete when VM is on different node" do
      State.create_vm("pve-node1", 100, %{})
      State.delete_vm("pve-node2", 100)
      :timer.sleep(10)
      assert State.get_vm("pve-node1", 100) != nil
    end
  end

  # --- Container operations ---

  describe "create_container/3" do
    test "creates a container" do
      assert {:ok, ct} = State.create_container("pve-node1", 200, %{hostname: "test-ct"})
      assert ct.vmid == 200
      assert ct.node == "pve-node1"
      assert ct.hostname == "test-ct"
      assert ct.type == "lxc"
      assert ct.status == "stopped"
    end

    test "returns error for duplicate vmid" do
      {:ok, _} = State.create_container("pve-node1", 200, %{})

      assert {:error, "Container 200 already exists"} =
               State.create_container("pve-node1", 200, %{})
    end
  end

  describe "get_containers/1" do
    test "returns containers for specific node" do
      State.create_container("pve-node1", 200, %{})
      State.create_container("pve-node2", 201, %{})

      assert length(State.get_containers("pve-node1")) == 1
    end

    test "returns all containers when node is nil" do
      State.create_container("pve-node1", 200, %{})
      State.create_container("pve-node2", 201, %{})

      assert length(State.get_containers(nil)) == 2
    end
  end

  describe "get_container/2" do
    test "returns container on correct node" do
      State.create_container("pve-node1", 200, %{})
      assert %{vmid: 200} = State.get_container("pve-node1", 200)
    end

    test "returns nil when container is on different node" do
      State.create_container("pve-node1", 200, %{})
      assert State.get_container("pve-node2", 200) == nil
    end
  end

  describe "update_container/3" do
    test "updates container config" do
      State.create_container("pve-node1", 200, %{})
      assert {:ok, ct} = State.update_container("pve-node1", 200, %{memory: 2048})
      assert ct.memory == 2048
    end

    test "returns error for nonexistent container" do
      assert {:error, "Container 999 not found"} = State.update_container("pve-node1", 999, %{})
    end

    test "returns error when container is on different node" do
      State.create_container("pve-node1", 200, %{})
      assert {:error, _} = State.update_container("pve-node2", 200, %{})
    end
  end

  describe "delete_container/2" do
    test "deletes a container" do
      State.create_container("pve-node1", 200, %{})
      State.delete_container("pve-node1", 200)
      :timer.sleep(10)
      assert State.get_container("pve-node1", 200) == nil
    end

    test "ignores delete when container is on different node" do
      State.create_container("pve-node1", 200, %{})
      State.delete_container("pve-node2", 200)
      :timer.sleep(10)
      assert State.get_container("pve-node1", 200) != nil
    end
  end

  # --- Storage operations ---

  describe "get_storage/0" do
    test "returns initial storage definitions" do
      storage = State.get_storage()
      assert length(storage) == 2
      ids = Enum.map(storage, & &1.storage)
      assert "local" in ids
      assert "local-lvm" in ids
    end
  end

  describe "get_storage_content/2" do
    test "returns content for dir storage" do
      content = State.get_storage_content("pve-node1", "local")
      assert length(content) == 2
      assert Enum.any?(content, &(&1.content == "iso"))
      assert Enum.any?(content, &(&1.content == "backup"))
    end

    test "returns content for lvmthin storage" do
      content = State.get_storage_content("pve-node1", "local-lvm")
      assert length(content) == 1
      assert hd(content).content == "images"
    end

    test "returns empty list for unknown storage" do
      assert State.get_storage_content("pve-node1", "nonexistent") == []
    end
  end

  describe "add_storage_content/3" do
    test "returns success for existing storage" do
      content = %{content: "iso", filename: "test.iso"}
      assert {:ok, ^content} = State.add_storage_content("pve-node1", "local", content)
    end

    test "returns error for unknown storage" do
      assert {:error, _} = State.add_storage_content("pve-node1", "nonexistent", %{})
    end
  end

  # --- Pool operations ---

  describe "pool CRUD" do
    test "creates, lists, and deletes pools" do
      assert State.get_pools() == []

      {:ok, pool} = State.create_pool("test-pool", %{comment: "Test"})
      assert pool.poolid == "test-pool"
      assert pool.comment == "Test"

      assert length(State.get_pools()) == 1

      State.delete_pool("test-pool")
      :timer.sleep(10)
      assert State.get_pools() == []
    end

    test "returns error for duplicate pool" do
      {:ok, _} = State.create_pool("dup", %{})
      assert {:error, "Pool dup already exists"} = State.create_pool("dup", %{})
    end

    test "updates pool comment" do
      {:ok, _} = State.create_pool("p1", %{comment: "old"})
      {:ok, updated} = State.update_pool("p1", %{"comment" => "new"})
      assert updated.comment == "new"
    end

    test "returns error when updating nonexistent pool" do
      assert {:error, _} = State.update_pool("nonexistent", %{})
    end
  end

  # --- Task operations ---

  describe "task operations" do
    test "creates and retrieves tasks" do
      {:ok, upid} = State.create_task("pve-node1", "qmstart", %{vmid: 100})
      assert is_binary(upid)
      assert String.starts_with?(upid, "UPID:pve-node1:")

      task = State.get_task(upid)
      assert task.type == "qmstart"
      assert task.node == "pve-node1"
    end

    test "lists tasks for a node" do
      {:ok, _} = State.create_task("pve-node1", "qmstart", %{})
      {:ok, _} = State.create_task("pve-node2", "qmstop", %{})

      tasks = State.get_tasks("pve-node1")
      assert length(tasks) == 1
      assert hd(tasks).type == "qmstart"
    end

    test "returns nil for nonexistent task" do
      assert State.get_task("nonexistent") == nil
    end

    test "updates task status" do
      {:ok, upid} = State.create_task("pve-node1", "qmstart", %{})
      State.update_task(upid, %{status: "failed"})
      :timer.sleep(10)
      assert State.get_task(upid).status == "failed"
    end

    test "ignores update for nonexistent task" do
      State.update_task("nonexistent", %{status: "failed"})
      :timer.sleep(10)
      # no crash
    end
  end

  # --- Authentication operations ---

  describe "create_ticket/3" do
    test "creates ticket for existing user" do
      {:ok, response} = State.create_ticket("root@pam", "password")
      assert response.username == "root@pam"
      assert is_binary(response.ticket)
      assert is_binary(Map.get(response, :CSRFPreventionToken))
    end

    test "returns error for unknown user" do
      assert {:error, "Authentication failed"} = State.create_ticket("unknown@pam", "pass")
    end
  end

  describe "validate_ticket/1" do
    test "validates a fresh ticket" do
      {:ok, response} = State.create_ticket("root@pam", "password")
      assert {:ok, ticket_data} = State.validate_ticket(response.ticket)
      assert ticket_data.username == "root@pam"
    end

    test "returns error for unknown ticket" do
      assert {:error, "Invalid ticket"} = State.validate_ticket("bogus-ticket")
    end
  end

  describe "create_api_token/3" do
    test "creates token for existing user" do
      {:ok, response} = State.create_api_token("root@pam", "mytoken")
      assert response.tokenid == "root@pam!mytoken"
      assert is_binary(response.value)
    end

    test "returns error for unknown user" do
      assert {:error, "User not found"} = State.create_api_token("unknown@pam", "tok")
    end
  end

  # --- User management ---

  describe "user CRUD" do
    test "creates and retrieves user" do
      {:ok, user} = State.create_user("test@pam", %{comment: "Test user"})
      assert user.userid == "test@pam"
      assert user.comment == "Test user"
    end

    test "returns error for duplicate user" do
      assert {:error, _} = State.create_user("root@pam", %{})
    end

    test "updates user" do
      {:ok, _} = State.create_user("test@pam", %{})
      {:ok, updated} = State.update_user("test@pam", %{comment: "Updated"})
      assert updated.comment == "Updated"
    end

    test "returns error updating nonexistent user" do
      assert {:error, _} = State.update_user("nonexistent@pam", %{})
    end

    test "deletes user" do
      {:ok, _} = State.create_user("test@pam", %{})
      assert :ok = State.delete_user("test@pam")
    end

    test "returns error deleting nonexistent user" do
      assert {:error, _} = State.delete_user("nonexistent@pam")
    end

    test "deleting user also removes their tokens" do
      {:ok, _} = State.create_user("test@pam", %{})
      {:ok, _} = State.create_api_token("test@pam", "tok1")
      :ok = State.delete_user("test@pam")
      assert {:error, _} = State.delete_api_token("test@pam!tok1")
    end
  end

  # --- Group management ---

  describe "group CRUD" do
    test "creates group" do
      {:ok, group} = State.create_group("devs", %{comment: "Developers"})
      assert group.groupid == "devs"
    end

    test "returns error for duplicate group" do
      assert {:error, _} = State.create_group("admin", %{})
    end

    test "updates group" do
      {:ok, _} = State.create_group("devs", %{})
      {:ok, updated} = State.update_group("devs", %{comment: "Updated"})
      assert updated.comment == "Updated"
    end

    test "returns error updating nonexistent group" do
      assert {:error, _} = State.update_group("nonexistent", %{})
    end

    test "deletes group" do
      {:ok, _} = State.create_group("devs", %{})
      assert :ok = State.delete_group("devs")
    end

    test "returns error deleting nonexistent group" do
      assert {:error, _} = State.delete_group("nonexistent")
    end
  end

  # --- API Token management ---

  describe "token management" do
    test "deletes token" do
      {:ok, _} = State.create_api_token("root@pam", "tok1")
      assert :ok = State.delete_api_token("root@pam!tok1")
    end

    test "returns error deleting nonexistent token" do
      assert {:error, _} = State.delete_api_token("nonexistent")
    end

    test "updates token metadata" do
      {:ok, _} = State.create_api_token("root@pam", "tok1")
      {:ok, updated} = State.update_api_token("root@pam!tok1", %{comment: "Updated"})
      assert updated.comment == "Updated"
    end

    test "returns error updating nonexistent token" do
      assert {:error, _} = State.update_api_token("nonexistent", %{})
    end
  end

  # --- Permission operations ---

  describe "permissions" do
    test "gets permissions for root" do
      perms = State.get_permissions("root@pam")
      assert length(perms) == 1
      assert hd(perms).path == "/"
      assert "Administrator" in hd(perms).roles
    end

    test "returns empty list for user with no permissions" do
      assert State.get_permissions("unknown@pam") == []
    end

    test "sets and retrieves permissions" do
      :ok = State.set_permissions("/vms", "root@pam", "PVEAdmin")
      perms = State.get_permissions("root@pam")
      vm_perm = Enum.find(perms, &(&1.path == "/vms"))
      assert "PVEAdmin" in vm_perm.roles
    end
  end

  # --- Cluster operations ---

  describe "cluster operations" do
    test "gets cluster status" do
      status = State.get_cluster_status()
      # 1 cluster entry + 2 nodes
      assert length(status) == 3
      assert Enum.any?(status, &(&1.type == "cluster"))
      assert Enum.count(status, &(&1.type == "node")) == 2
    end

    test "gets cluster config" do
      config = State.get_cluster_config()
      assert config.cluster_name == "pve-cluster"
      assert map_size(config.nodes) == 2
    end

    test "updates cluster config" do
      {:ok, config} = State.update_cluster_config(%{"cluster_name" => "new-cluster"})
      assert config.cluster_name == "new-cluster"
    end

    test "gets cluster nodes config" do
      nodes = State.get_cluster_nodes_config()
      assert length(nodes) == 2
    end

    test "joins a node to cluster" do
      {:ok, upid} = State.join_cluster("pve-node3", nil, 1)
      assert is_binary(upid)

      nodes = State.get_nodes()
      assert length(nodes) == 3
      assert Enum.any?(nodes, &(&1.node == "pve-node3"))
    end

    test "removes a node from cluster" do
      {:ok, _} = State.remove_cluster_node("pve-node2")
      nodes = State.get_nodes()
      assert length(nodes) == 1
      refute Enum.any?(nodes, &(&1.node == "pve-node2"))
    end

    test "returns error removing nonexistent node" do
      assert {:error, _} = State.remove_cluster_node("nonexistent")
    end
  end

  # --- Backup operations ---

  describe "backup operations" do
    test "creates and lists backups" do
      State.create_vm("pve-node1", 100, %{})
      {:ok, upid} = State.create_backup("pve-node1", 100)
      assert is_binary(upid)

      backups = State.list_backups("pve-node1", "local")
      assert length(backups) == 1
      assert hd(backups).vmid == 100
    end

    test "restores backup" do
      State.create_vm("pve-node1", 100, %{})
      {:ok, _} = State.create_backup("pve-node1", 100)
      backups = State.list_backups("pve-node1", "local")
      backup_file = hd(backups).filename

      {:ok, upid} = State.restore_backup("pve-node1", 100, backup_file)
      assert is_binary(upid)
    end

    test "returns error restoring nonexistent backup" do
      assert {:error, "Backup file not found"} =
               State.restore_backup("pve-node1", 100, "nonexistent.vma.zst")
    end
  end

  # --- Migration operations ---

  describe "migrate_vm/4" do
    test "migrates VM to another node" do
      State.create_vm("pve-node1", 100, %{})
      {:ok, upid} = State.migrate_vm("pve-node1", 100, "pve-node2")
      assert is_binary(upid)

      # VM should now be on pve-node2
      assert State.get_vm("pve-node2", 100) != nil
      assert State.get_vm("pve-node1", 100) == nil
    end

    test "returns error for nonexistent VM" do
      assert {:error, _} = State.migrate_vm("pve-node1", 999, "pve-node2")
    end

    test "returns error when VM is on different node" do
      State.create_vm("pve-node1", 100, %{})
      assert {:error, _} = State.migrate_vm("pve-node2", 100, "pve-node1")
    end
  end

  describe "migrate_container/4" do
    test "migrates container to another node" do
      State.create_container("pve-node1", 200, %{})
      {:ok, upid} = State.migrate_container("pve-node1", 200, "pve-node2")
      assert is_binary(upid)

      assert State.get_container("pve-node2", 200) != nil
      assert State.get_container("pve-node1", 200) == nil
    end

    test "returns error for nonexistent container" do
      assert {:error, _} = State.migrate_container("pve-node1", 999, "pve-node2")
    end

    test "returns error when container is on different node" do
      State.create_container("pve-node1", 200, %{})
      assert {:error, _} = State.migrate_container("pve-node2", 200, "pve-node1")
    end
  end

  # --- Version and capability operations ---

  describe "version operations" do
    test "returns configured PVE version" do
      version = State.get_pve_version()
      assert is_binary(version)
    end

    test "returns capabilities list" do
      caps = State.get_capabilities()
      assert is_list(caps)
      assert :basic_virtualization in caps
    end

    test "checks capability presence" do
      assert State.has_capability?(:basic_virtualization) == true
    end

    test "checks endpoint support" do
      assert is_boolean(State.endpoint_supported?("/api2/json/version"))
    end
  end

  # --- Reset ---

  describe "reset/0" do
    test "restores initial state" do
      State.create_vm("pve-node1", 100, %{})
      State.create_pool("test", %{})
      State.reset()

      assert State.get_vms("pve-node1") == []
      assert State.get_pools() == []
      assert length(State.get_nodes()) == 2
    end
  end

  # --- Next VMID ---

  describe "get_next_vmid/0" do
    test "increments on each call" do
      id1 = State.get_next_vmid()
      id2 = State.get_next_vmid()
      assert id2 == id1 + 1
    end
  end
end
