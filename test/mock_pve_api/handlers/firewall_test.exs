# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.FirewallTest do
  @moduledoc """
  Tests for firewall handler endpoints including cluster-level and node-level
  options, rules, security groups, aliases, and IP sets.
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
      # Add rule to group (using cluster rules POST won't work - need to use state directly)
      # Actually, PVE API uses POST on the group endpoint to add rules.
      # Our implementation: the group endpoint GET returns rules, POST on groups creates groups.
      # Group rules are managed via /{group}/{pos} CRUD endpoints.
      # To add a rule, we need to update state directly for now since
      # the plan only has CRUD on existing positions.

      # Let's add a rule via state manipulation and then test the CRUD
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
end
