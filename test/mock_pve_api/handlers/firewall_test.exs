# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.FirewallTest do
  @moduledoc """
  Tests for firewall handler endpoints including cluster-level, node-level,
  VM-level, and container-level options, rules, security groups, aliases,
  and IP sets.
  """

  use ExUnit.Case, async: false

  alias MockPveApi.State

  setup do
    State.reset()
    :ok
  end

  defp request(method, path, body \\ nil) do
    conn =
      Plug.Test.conn(method, path, body && Jason.encode!(body))
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("authorization", "PVEAPIToken=root@pam!test=secret")

    MockPveApi.Router.call(conn, MockPveApi.Router.init([]))
  end

  defp json(conn, status) do
    assert conn.status == status
    Jason.decode!(conn.resp_body)
  end

  # ── Cluster Firewall Options ──

  describe "cluster firewall options" do
    test "GET returns default options" do
      resp = request(:get, "/api2/json/cluster/firewall/options") |> json(200)
      assert resp["data"]["enable"] == 0
      assert resp["data"]["policy_in"] == "DROP"
      assert resp["data"]["policy_out"] == "ACCEPT"
    end

    test "PUT updates options" do
      request(:put, "/api2/json/cluster/firewall/options", %{enable: 1})
      |> json(200)

      resp = request(:get, "/api2/json/cluster/firewall/options") |> json(200)
      assert resp["data"]["enable"] == 1
      # Other options remain
      assert resp["data"]["policy_in"] == "DROP"
    end
  end

  # ── Cluster Firewall Rules ──

  describe "cluster firewall rules" do
    test "GET returns empty rules initially" do
      resp = request(:get, "/api2/json/cluster/firewall/rules") |> json(200)
      assert resp["data"] == []
    end

    test "POST creates rule, GET lists it" do
      request(:post, "/api2/json/cluster/firewall/rules", %{
        type: "in",
        action: "ACCEPT",
        source: "10.0.0.0/24",
        comment: "allow LAN"
      })
      |> json(200)

      resp = request(:get, "/api2/json/cluster/firewall/rules") |> json(200)
      assert length(resp["data"]) == 1
      [rule] = resp["data"]
      assert rule["pos"] == 0
      assert rule["action"] == "ACCEPT"
      assert rule["source"] == "10.0.0.0/24"
    end

    test "GET/PUT/DELETE individual rule by position" do
      # Create two rules
      request(:post, "/api2/json/cluster/firewall/rules", %{action: "ACCEPT", comment: "rule0"})
      request(:post, "/api2/json/cluster/firewall/rules", %{action: "DROP", comment: "rule1"})

      # GET individual
      resp = request(:get, "/api2/json/cluster/firewall/rules/1") |> json(200)
      assert resp["data"]["action"] == "DROP"
      assert resp["data"]["pos"] == 1

      # PUT update
      request(:put, "/api2/json/cluster/firewall/rules/1", %{action: "REJECT"}) |> json(200)
      resp = request(:get, "/api2/json/cluster/firewall/rules/1") |> json(200)
      assert resp["data"]["action"] == "REJECT"

      # DELETE
      request(:delete, "/api2/json/cluster/firewall/rules/0") |> json(200)
      resp = request(:get, "/api2/json/cluster/firewall/rules") |> json(200)
      assert length(resp["data"]) == 1
      assert hd(resp["data"])["action"] == "REJECT"
    end

    test "GET non-existent rule position returns error" do
      request(:get, "/api2/json/cluster/firewall/rules/99") |> json(400)
    end
  end

  # ── Security Groups ──

  describe "security groups" do
    test "GET returns empty groups initially" do
      resp = request(:get, "/api2/json/cluster/firewall/groups") |> json(200)
      assert resp["data"] == []
    end

    test "POST creates group, GET lists it" do
      request(:post, "/api2/json/cluster/firewall/groups", %{
        group: "webservers",
        comment: "Web server rules"
      })
      |> json(200)

      resp = request(:get, "/api2/json/cluster/firewall/groups") |> json(200)
      assert length(resp["data"]) == 1
      [group] = resp["data"]
      assert group["group"] == "webservers"
      assert group["comment"] == "Web server rules"
    end

    test "GET group returns its rules" do
      request(:post, "/api2/json/cluster/firewall/groups", %{group: "mygroup"})

      resp = request(:get, "/api2/json/cluster/firewall/groups/mygroup") |> json(200)
      assert resp["data"] == []
    end

    test "DELETE group removes it" do
      request(:post, "/api2/json/cluster/firewall/groups", %{group: "temp"})
      request(:delete, "/api2/json/cluster/firewall/groups/temp") |> json(200)

      resp = request(:get, "/api2/json/cluster/firewall/groups") |> json(200)
      assert resp["data"] == []
    end

    test "POST duplicate group returns error" do
      request(:post, "/api2/json/cluster/firewall/groups", %{group: "dup"})
      request(:post, "/api2/json/cluster/firewall/groups", %{group: "dup"}) |> json(400)
    end

    test "POST without group name returns error" do
      request(:post, "/api2/json/cluster/firewall/groups", %{comment: "no name"}) |> json(400)
    end

    test "DELETE non-existent group returns 404" do
      request(:delete, "/api2/json/cluster/firewall/groups/nope") |> json(404)
    end
  end

  # ── Security Group Rules ──

  describe "security group rules" do
    setup do
      request(:post, "/api2/json/cluster/firewall/groups", %{group: "testgrp"})
      :ok
    end

    test "CRUD lifecycle for group rules" do
      # Add a rule via state manipulation and then test the CRUD
      fw = State.get_firewall(:cluster)

      group = Map.get(fw.groups, "testgrp")
      rule = %{type: "in", action: "ACCEPT", comment: "test rule"}
      new_group = %{group | rules: [rule]}
      new_groups = Map.put(fw.groups, "testgrp", new_group)
      State.update_firewall(:cluster, %{groups: new_groups})

      # GET rule by position
      resp =
        request(:get, "/api2/json/cluster/firewall/groups/testgrp/0")
        |> json(200)

      assert resp["data"]["action"] == "ACCEPT"
      assert resp["data"]["pos"] == 0

      # PUT update rule
      request(:put, "/api2/json/cluster/firewall/groups/testgrp/0", %{action: "DROP"})
      |> json(200)

      resp =
        request(:get, "/api2/json/cluster/firewall/groups/testgrp/0")
        |> json(200)

      assert resp["data"]["action"] == "DROP"

      # DELETE rule
      request(:delete, "/api2/json/cluster/firewall/groups/testgrp/0")
      |> json(200)

      resp =
        request(:get, "/api2/json/cluster/firewall/groups/testgrp")
        |> json(200)

      assert resp["data"] == []
    end

    test "GET non-existent group rule returns 404 for group" do
      request(:get, "/api2/json/cluster/firewall/groups/nosuch/0") |> json(404)
    end

    test "GET non-existent rule position returns 400" do
      request(:get, "/api2/json/cluster/firewall/groups/testgrp/99") |> json(400)
    end
  end

  # ── Cluster Aliases ──

  describe "cluster aliases" do
    test "GET returns empty aliases initially" do
      resp = request(:get, "/api2/json/cluster/firewall/aliases") |> json(200)
      assert resp["data"] == []
    end

    test "CRUD lifecycle" do
      # Create
      request(:post, "/api2/json/cluster/firewall/aliases", %{
        name: "local_net",
        cidr: "192.168.1.0/24",
        comment: "Local network"
      })
      |> json(200)

      # List
      resp = request(:get, "/api2/json/cluster/firewall/aliases") |> json(200)
      assert length(resp["data"]) == 1
      [alias_entry] = resp["data"]
      assert alias_entry["name"] == "local_net"
      assert alias_entry["cidr"] == "192.168.1.0/24"

      # Get individual
      resp = request(:get, "/api2/json/cluster/firewall/aliases/local_net") |> json(200)
      assert resp["data"]["cidr"] == "192.168.1.0/24"

      # Update
      request(:put, "/api2/json/cluster/firewall/aliases/local_net", %{cidr: "10.0.0.0/8"})
      |> json(200)

      resp = request(:get, "/api2/json/cluster/firewall/aliases/local_net") |> json(200)
      assert resp["data"]["cidr"] == "10.0.0.0/8"

      # Delete
      request(:delete, "/api2/json/cluster/firewall/aliases/local_net") |> json(200)
      resp = request(:get, "/api2/json/cluster/firewall/aliases") |> json(200)
      assert resp["data"] == []
    end

    test "POST duplicate alias returns error" do
      request(:post, "/api2/json/cluster/firewall/aliases", %{name: "dup", cidr: "1.2.3.4"})

      request(:post, "/api2/json/cluster/firewall/aliases", %{name: "dup", cidr: "5.6.7.8"})
      |> json(400)
    end

    test "GET non-existent alias returns 404" do
      request(:get, "/api2/json/cluster/firewall/aliases/nope") |> json(404)
    end
  end

  # ── Cluster IP Sets ──

  describe "cluster IP sets" do
    test "GET returns empty ipsets initially" do
      resp = request(:get, "/api2/json/cluster/firewall/ipset") |> json(200)
      assert resp["data"] == []
    end

    test "CRUD lifecycle for ipsets and entries" do
      # Create ipset
      request(:post, "/api2/json/cluster/firewall/ipset", %{
        name: "blocklist",
        comment: "Blocked IPs"
      })
      |> json(200)

      # List ipsets
      resp = request(:get, "/api2/json/cluster/firewall/ipset") |> json(200)
      assert length(resp["data"]) == 1
      [ipset] = resp["data"]
      assert ipset["name"] == "blocklist"
      assert ipset["count"] == 0

      # Get ipset entries (empty)
      resp = request(:get, "/api2/json/cluster/firewall/ipset/blocklist") |> json(200)
      assert resp["data"] == []

      # Add entry via POST on ipset name
      request(:post, "/api2/json/cluster/firewall/ipset/blocklist", %{
        cidr: "10.0.0.0/24",
        comment: "blocked subnet"
      })
      |> json(200)

      # List entries
      resp = request(:get, "/api2/json/cluster/firewall/ipset/blocklist") |> json(200)
      assert length(resp["data"]) == 1
      [entry] = resp["data"]
      assert entry["cidr"] == "10.0.0.0/24"

      # Get individual entry (URL uses dash notation for CIDR)
      resp =
        request(:get, "/api2/json/cluster/firewall/ipset/blocklist/10.0.0.0-24")
        |> json(200)

      assert resp["data"]["cidr"] == "10.0.0.0/24"

      # Update entry
      request(
        :put,
        "/api2/json/cluster/firewall/ipset/blocklist/10.0.0.0-24",
        %{comment: "updated"}
      )
      |> json(200)

      resp =
        request(:get, "/api2/json/cluster/firewall/ipset/blocklist/10.0.0.0-24")
        |> json(200)

      assert resp["data"]["comment"] == "updated"

      # Delete entry
      request(:delete, "/api2/json/cluster/firewall/ipset/blocklist/10.0.0.0-24")
      |> json(200)

      resp = request(:get, "/api2/json/cluster/firewall/ipset/blocklist") |> json(200)
      assert resp["data"] == []

      # Delete ipset
      request(:delete, "/api2/json/cluster/firewall/ipset/blocklist") |> json(200)
      resp = request(:get, "/api2/json/cluster/firewall/ipset") |> json(200)
      assert resp["data"] == []
    end

    test "POST duplicate ipset returns error" do
      request(:post, "/api2/json/cluster/firewall/ipset", %{name: "dup"})
      request(:post, "/api2/json/cluster/firewall/ipset", %{name: "dup"}) |> json(400)
    end

    test "GET non-existent ipset returns 404" do
      request(:get, "/api2/json/cluster/firewall/ipset/nope") |> json(404)
    end

    test "GET non-existent ipset entry returns 404" do
      request(:post, "/api2/json/cluster/firewall/ipset", %{name: "test"})
      request(:get, "/api2/json/cluster/firewall/ipset/test/1.2.3.4-32") |> json(404)
    end
  end

  # ── Node Firewall Options ──

  describe "node firewall options" do
    test "GET returns default options" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/firewall/options")
        |> json(200)

      assert resp["data"]["enable"] == 0
    end

    test "PUT updates options" do
      request(:put, "/api2/json/nodes/pve-node1/firewall/options", %{enable: 1})
      |> json(200)

      resp =
        request(:get, "/api2/json/nodes/pve-node1/firewall/options")
        |> json(200)

      assert resp["data"]["enable"] == 1
    end
  end

  # ── Node Firewall Rules ──

  describe "node firewall rules" do
    test "GET returns empty rules initially" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/firewall/rules")
        |> json(200)

      assert resp["data"] == []
    end

    test "POST creates rule, GET lists it" do
      request(:post, "/api2/json/nodes/pve-node1/firewall/rules", %{
        action: "ACCEPT",
        type: "in",
        proto: "tcp",
        dport: "22",
        comment: "SSH"
      })
      |> json(200)

      resp =
        request(:get, "/api2/json/nodes/pve-node1/firewall/rules")
        |> json(200)

      assert length(resp["data"]) == 1
      [rule] = resp["data"]
      assert rule["action"] == "ACCEPT"
      assert rule["dport"] == "22"
    end

    test "GET/PUT/DELETE individual rule by position" do
      request(:post, "/api2/json/nodes/pve-node1/firewall/rules", %{
        action: "ACCEPT",
        comment: "r0"
      })

      request(:post, "/api2/json/nodes/pve-node1/firewall/rules", %{
        action: "DROP",
        comment: "r1"
      })

      # GET
      resp =
        request(:get, "/api2/json/nodes/pve-node1/firewall/rules/1")
        |> json(200)

      assert resp["data"]["action"] == "DROP"

      # PUT
      request(:put, "/api2/json/nodes/pve-node1/firewall/rules/1", %{action: "REJECT"})
      |> json(200)

      resp =
        request(:get, "/api2/json/nodes/pve-node1/firewall/rules/1")
        |> json(200)

      assert resp["data"]["action"] == "REJECT"

      # DELETE
      request(:delete, "/api2/json/nodes/pve-node1/firewall/rules/0")
      |> json(200)

      resp =
        request(:get, "/api2/json/nodes/pve-node1/firewall/rules")
        |> json(200)

      assert length(resp["data"]) == 1
    end

    test "node rules are independent per node" do
      request(:post, "/api2/json/nodes/pve-node1/firewall/rules", %{action: "ACCEPT"})
      request(:post, "/api2/json/nodes/pve-node2/firewall/rules", %{action: "DROP"})

      resp1 =
        request(:get, "/api2/json/nodes/pve-node1/firewall/rules")
        |> json(200)

      resp2 =
        request(:get, "/api2/json/nodes/pve-node2/firewall/rules")
        |> json(200)

      assert hd(resp1["data"])["action"] == "ACCEPT"
      assert hd(resp2["data"])["action"] == "DROP"
    end
  end

  # ── VM Firewall Options ──

  describe "VM firewall options" do
    test "GET returns default options" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/firewall/options")
        |> json(200)

      assert resp["data"]["enable"] == 0
      assert resp["data"]["policy_in"] == "DROP"
      assert resp["data"]["macfilter"] == 1
    end

    test "PUT updates options" do
      request(:put, "/api2/json/nodes/pve-node1/qemu/100/firewall/options", %{enable: 1})
      |> json(200)

      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/firewall/options")
        |> json(200)

      assert resp["data"]["enable"] == 1
      # Other defaults remain
      assert resp["data"]["macfilter"] == 1
    end
  end

  # ── VM Firewall Rules ──

  describe "VM firewall rules" do
    test "GET returns empty rules initially" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/firewall/rules")
        |> json(200)

      assert resp["data"] == []
    end

    test "CRUD lifecycle" do
      # Create
      request(:post, "/api2/json/nodes/pve-node1/qemu/100/firewall/rules", %{
        action: "ACCEPT",
        type: "in",
        proto: "tcp",
        dport: "80",
        comment: "HTTP"
      })
      |> json(200)

      request(:post, "/api2/json/nodes/pve-node1/qemu/100/firewall/rules", %{
        action: "DROP",
        comment: "block all"
      })
      |> json(200)

      # List
      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/firewall/rules")
        |> json(200)

      assert length(resp["data"]) == 2
      assert hd(resp["data"])["action"] == "ACCEPT"

      # GET individual
      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/firewall/rules/1")
        |> json(200)

      assert resp["data"]["action"] == "DROP"
      assert resp["data"]["pos"] == 1

      # PUT update
      request(:put, "/api2/json/nodes/pve-node1/qemu/100/firewall/rules/1", %{action: "REJECT"})
      |> json(200)

      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/firewall/rules/1")
        |> json(200)

      assert resp["data"]["action"] == "REJECT"

      # DELETE
      request(:delete, "/api2/json/nodes/pve-node1/qemu/100/firewall/rules/0")
      |> json(200)

      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/firewall/rules")
        |> json(200)

      assert length(resp["data"]) == 1
      assert hd(resp["data"])["action"] == "REJECT"
    end

    test "GET non-existent position returns 400" do
      request(:get, "/api2/json/nodes/pve-node1/qemu/100/firewall/rules/99") |> json(400)
    end
  end

  # ── VM Firewall Aliases ──

  describe "VM firewall aliases" do
    @base "/api2/json/nodes/pve-node1/qemu/100/firewall/aliases"

    test "CRUD lifecycle" do
      # Empty initially
      resp = request(:get, @base) |> json(200)
      assert resp["data"] == []

      # Create
      request(:post, @base, %{name: "webserver", cidr: "10.0.0.5/32", comment: "web"})
      |> json(200)

      # List
      resp = request(:get, @base) |> json(200)
      assert length(resp["data"]) == 1
      assert hd(resp["data"])["name"] == "webserver"

      # Get individual
      resp = request(:get, "#{@base}/webserver") |> json(200)
      assert resp["data"]["cidr"] == "10.0.0.5/32"

      # Update
      request(:put, "#{@base}/webserver", %{cidr: "10.0.0.10/32"}) |> json(200)
      resp = request(:get, "#{@base}/webserver") |> json(200)
      assert resp["data"]["cidr"] == "10.0.0.10/32"

      # Delete
      request(:delete, "#{@base}/webserver") |> json(200)
      resp = request(:get, @base) |> json(200)
      assert resp["data"] == []
    end

    test "POST duplicate alias returns 400" do
      request(:post, @base, %{name: "dup", cidr: "1.2.3.4"})
      request(:post, @base, %{name: "dup", cidr: "5.6.7.8"}) |> json(400)
    end

    test "GET non-existent alias returns 404" do
      request(:get, "#{@base}/nosuch") |> json(404)
    end
  end

  # ── VM Firewall IP Sets ──

  describe "VM firewall IP sets" do
    @base "/api2/json/nodes/pve-node1/qemu/100/firewall/ipset"

    test "CRUD lifecycle for ipsets and entries" do
      # Empty initially
      resp = request(:get, @base) |> json(200)
      assert resp["data"] == []

      # Create ipset
      request(:post, @base, %{name: "allowed", comment: "Allowed IPs"}) |> json(200)

      # List
      resp = request(:get, @base) |> json(200)
      assert length(resp["data"]) == 1
      assert hd(resp["data"])["name"] == "allowed"
      assert hd(resp["data"])["count"] == 0

      # Add entry
      request(:post, "#{@base}/allowed", %{cidr: "192.168.1.0/24", comment: "LAN"})
      |> json(200)

      # List entries
      resp = request(:get, "#{@base}/allowed") |> json(200)
      assert length(resp["data"]) == 1
      assert hd(resp["data"])["cidr"] == "192.168.1.0/24"

      # Get individual entry
      resp = request(:get, "#{@base}/allowed/192.168.1.0-24") |> json(200)
      assert resp["data"]["cidr"] == "192.168.1.0/24"

      # Update entry
      request(:put, "#{@base}/allowed/192.168.1.0-24", %{comment: "updated LAN"})
      |> json(200)

      resp = request(:get, "#{@base}/allowed/192.168.1.0-24") |> json(200)
      assert resp["data"]["comment"] == "updated LAN"

      # Delete entry
      request(:delete, "#{@base}/allowed/192.168.1.0-24") |> json(200)
      resp = request(:get, "#{@base}/allowed") |> json(200)
      assert resp["data"] == []

      # Delete ipset
      request(:delete, "#{@base}/allowed") |> json(200)
      resp = request(:get, @base) |> json(200)
      assert resp["data"] == []
    end
  end

  # ── VM Firewall Refs and Log ──

  describe "VM firewall refs and log" do
    test "GET refs returns reference types" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/firewall/refs")
        |> json(200)

      assert is_list(resp["data"])
      types = Enum.map(resp["data"], & &1["type"])
      assert "alias" in types
      assert "ipset" in types
    end

    test "GET log returns empty list" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/firewall/log")
        |> json(200)

      assert resp["data"] == []
    end

    test "GET firewall index returns sub-resource list" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/firewall")
        |> json(200)

      names = Enum.map(resp["data"], & &1["name"])
      assert "options" in names
      assert "rules" in names
      assert "aliases" in names
      assert "ipset" in names
      assert "refs" in names
      assert "log" in names
    end
  end

  # ── Container Firewall ──

  describe "container firewall" do
    test "options GET returns defaults" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/lxc/200/firewall/options")
        |> json(200)

      assert resp["data"]["enable"] == 0
      assert resp["data"]["policy_in"] == "DROP"
    end

    test "options PUT updates" do
      request(:put, "/api2/json/nodes/pve-node1/lxc/200/firewall/options", %{enable: 1})
      |> json(200)

      resp =
        request(:get, "/api2/json/nodes/pve-node1/lxc/200/firewall/options")
        |> json(200)

      assert resp["data"]["enable"] == 1
    end

    test "rules CRUD lifecycle" do
      base = "/api2/json/nodes/pve-node1/lxc/200/firewall/rules"

      # Empty initially
      resp = request(:get, base) |> json(200)
      assert resp["data"] == []

      # Create
      request(:post, base, %{action: "ACCEPT", type: "in", dport: "443"}) |> json(200)

      # List
      resp = request(:get, base) |> json(200)
      assert length(resp["data"]) == 1
      assert hd(resp["data"])["action"] == "ACCEPT"

      # GET individual
      resp = request(:get, "#{base}/0") |> json(200)
      assert resp["data"]["dport"] == "443"

      # PUT
      request(:put, "#{base}/0", %{action: "DROP"}) |> json(200)
      resp = request(:get, "#{base}/0") |> json(200)
      assert resp["data"]["action"] == "DROP"

      # DELETE
      request(:delete, "#{base}/0") |> json(200)
      resp = request(:get, base) |> json(200)
      assert resp["data"] == []
    end

    test "firewall index returns sub-resources" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/lxc/200/firewall")
        |> json(200)

      names = Enum.map(resp["data"], & &1["name"])
      assert "options" in names
      assert "rules" in names
    end

    test "refs and log static endpoints" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/lxc/200/firewall/refs")
        |> json(200)

      assert is_list(resp["data"])

      resp =
        request(:get, "/api2/json/nodes/pve-node1/lxc/200/firewall/log")
        |> json(200)

      assert resp["data"] == []
    end
  end

  # ── Cluster Firewall Refs, Macros, Log ──

  describe "cluster firewall refs" do
    test "GET returns reference types" do
      resp = request(:get, "/api2/json/cluster/firewall/refs") |> json(200)
      assert is_list(resp["data"])
      types = Enum.map(resp["data"], & &1["type"])
      assert "alias" in types
      assert "ipset" in types
    end
  end

  describe "cluster firewall macros" do
    test "GET returns list of macros" do
      resp = request(:get, "/api2/json/cluster/firewall/macros") |> json(200)
      assert is_list(resp["data"])
      names = Enum.map(resp["data"], & &1["macro"])
      assert "SSH" in names
      assert "HTTP" in names
      assert "DNS" in names
      assert "Ping" in names
    end
  end

  describe "cluster firewall log" do
    test "GET returns empty log" do
      resp = request(:get, "/api2/json/cluster/firewall/log") |> json(200)
      assert resp["data"] == []
    end
  end

  # ── Node Firewall Index & Log ──

  describe "node firewall index" do
    test "GET returns sub-resource list" do
      resp = request(:get, "/api2/json/nodes/pve-node1/firewall") |> json(200)
      names = Enum.map(resp["data"], & &1["name"])
      assert "options" in names
      assert "rules" in names
      assert "log" in names
    end
  end

  describe "node firewall log" do
    test "GET returns empty log" do
      resp = request(:get, "/api2/json/nodes/pve-node1/firewall/log") |> json(200)
      assert resp["data"] == []
    end
  end

  # ── VM/CT Isolation ──

  describe "VM/CT firewall isolation" do
    test "different VMIDs have independent state" do
      # Create rule on VM 100
      request(:post, "/api2/json/nodes/pve-node1/qemu/100/firewall/rules", %{
        action: "ACCEPT",
        comment: "vm100"
      })
      |> json(200)

      # Create rule on VM 101
      request(:post, "/api2/json/nodes/pve-node1/qemu/101/firewall/rules", %{
        action: "DROP",
        comment: "vm101"
      })
      |> json(200)

      # Verify isolation
      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/firewall/rules")
        |> json(200)

      assert length(resp["data"]) == 1
      assert hd(resp["data"])["action"] == "ACCEPT"

      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/101/firewall/rules")
        |> json(200)

      assert length(resp["data"]) == 1
      assert hd(resp["data"])["action"] == "DROP"
    end

    test "VM and container firewalls are independent" do
      # Create alias on VM 100
      request(:post, "/api2/json/nodes/pve-node1/qemu/100/firewall/aliases", %{
        name: "shared_name",
        cidr: "10.0.0.1/32"
      })
      |> json(200)

      # Create alias with same name on CT 100
      request(:post, "/api2/json/nodes/pve-node1/lxc/100/firewall/aliases", %{
        name: "shared_name",
        cidr: "10.0.0.2/32"
      })
      |> json(200)

      # Verify they are independent
      vm_resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/firewall/aliases/shared_name")
        |> json(200)

      ct_resp =
        request(:get, "/api2/json/nodes/pve-node1/lxc/100/firewall/aliases/shared_name")
        |> json(200)

      assert vm_resp["data"]["cidr"] == "10.0.0.1/32"
      assert ct_resp["data"]["cidr"] == "10.0.0.2/32"
    end
  end
end
