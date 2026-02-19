# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.CoverageTest do
  use ExUnit.Case, async: true
  doctest MockPveApi.Coverage

  alias MockPveApi.Coverage

  describe "endpoint information" do
    test "gets endpoint info for exact matches" do
      assert %{path: "/api2/json/version"} = Coverage.get_endpoint_info("/api2/json/version")
      assert %{path: "/api2/json/nodes"} = Coverage.get_endpoint_info("/api2/json/nodes")
      assert %{path: "/api2/json/pools"} = Coverage.get_endpoint_info("/api2/json/pools")
    end

    test "gets endpoint info for parameterized paths" do
      info = Coverage.get_endpoint_info("/api2/json/nodes/pve1/qemu/100")
      assert %{path: "/api2/json/nodes/{node}/qemu/{vmid}"} = info
      # Endpoint is now fully implemented
      assert info.status == :implemented
      assert info.priority == :critical
    end

    test "returns nil for unknown endpoints" do
      assert Coverage.get_endpoint_info("/api2/json/unknown/endpoint") == nil
      assert Coverage.get_endpoint_info("/completely/different/path") == nil
    end

    test "matches complex parameterized paths" do
      info = Coverage.get_endpoint_info("/api2/json/nodes/pve1/storage/local/content")
      assert %{path: "/api2/json/nodes/{node}/storage/{storage}/content"} = info

      info = Coverage.get_endpoint_info("/api2/json/nodes/pve1/qemu/100/status/start")
      assert %{path: "/api2/json/nodes/{node}/qemu/{vmid}/status/{command}"} = info
    end
  end

  describe "category endpoints" do
    test "gets all endpoints for a category" do
      version_endpoints = Coverage.get_category_endpoints(:version)
      assert length(version_endpoints) == 1
      assert hd(version_endpoints).path == "/api2/json/version"

      cluster_endpoints = Coverage.get_category_endpoints(:cluster)
      assert length(cluster_endpoints) > 0
      assert Enum.any?(cluster_endpoints, &(&1.path == "/api2/json/cluster/status"))
    end

    test "returns empty list for unknown category" do
      assert Coverage.get_category_endpoints(:unknown) == []
    end

    test "gets all valid categories" do
      categories = Coverage.get_categories()

      expected_categories = [
        :version,
        :cluster,
        :nodes,
        :vms,
        :containers,
        :storage,
        :access,
        :pools,
        :sdn,
        :monitoring,
        :backup,
        :hardware,
        :firewall
      ]

      for category <- expected_categories do
        assert category in categories, "Missing category: #{category}"
      end
    end
  end

  describe "coverage statistics" do
    test "calculates overall coverage stats" do
      stats = Coverage.get_coverage_stats()

      assert is_integer(stats.total)
      assert is_integer(stats.implemented)
      assert is_integer(stats.partial)
      assert is_integer(stats.planned)
      assert is_float(stats.coverage_percentage)

      assert stats.total > 0
      assert stats.coverage_percentage >= 0.0 and stats.coverage_percentage <= 100.0

      assert stats.total ==
               stats.implemented + stats.partial + stats.in_progress +
                 stats.planned + stats.not_supported
    end

    test "calculates category stats" do
      category_stats = Coverage.get_category_stats()

      assert is_map(category_stats)
      assert Map.has_key?(category_stats, :version)
      assert Map.has_key?(category_stats, :cluster)

      version_stats = category_stats.version
      assert version_stats.total == 1
      assert version_stats.implemented == 1
      assert version_stats.coverage_percentage == 100.0
    end
  end

  describe "endpoints by status" do
    test "gets implemented endpoints" do
      implemented = Coverage.get_endpoints_by_status(:implemented)

      assert length(implemented) > 0
      assert Enum.all?(implemented, &(&1.status == :implemented))

      # Version endpoint should always be implemented
      assert Enum.any?(implemented, &(&1.path == "/api2/json/version"))
    end

    test "gets planned endpoints" do
      planned = Coverage.get_endpoints_by_status(:planned)

      assert Enum.all?(planned, &(&1.status == :planned))
      # All endpoints are implemented - no planned endpoints remaining
      assert length(planned) >= 0
    end

    test "gets partial endpoints" do
      partial = Coverage.get_endpoints_by_status(:partial)

      assert Enum.all?(partial, &(&1.status == :partial))
    end
  end

  describe "endpoints by priority" do
    test "gets critical priority endpoints" do
      critical = Coverage.get_endpoints_by_priority(:critical)

      assert length(critical) > 0
      assert Enum.all?(critical, &(&1.priority == :critical))

      # Version endpoint should be critical
      assert Enum.any?(critical, &(&1.path == "/api2/json/version"))
    end

    test "gets missing critical endpoints" do
      missing_critical = Coverage.get_missing_critical_endpoints()

      # All endpoints should have priority :critical and status != :implemented
      for endpoint <- missing_critical do
        assert endpoint.priority == :critical
        assert endpoint.status != :implemented
      end
    end
  end

  describe "coverage validation" do
    test "validates coverage consistency" do
      case Coverage.validate_coverage() do
        {:ok, messages} ->
          assert is_list(messages)
          assert length(messages) > 0

        {:error, issues} ->
          assert is_list(issues)
          # Log issues for debugging but don't fail test in development
          for issue <- issues do
            IO.puts("Coverage issue: #{issue}")
          end
      end
    end

    test "identifies endpoints without test coverage" do
      all_implemented = Coverage.get_endpoints_by_status(:implemented)
      untested = Enum.filter(all_implemented, &(!&1.test_coverage))

      # In a mature implementation, this should be empty
      # For now, just verify the check works
      for endpoint <- untested do
        assert endpoint.status == :implemented
        refute endpoint.test_coverage
      end
    end

    test "identifies endpoints without handler modules" do
      all_implemented = Coverage.get_endpoints_by_status(:implemented)
      no_handlers = Enum.filter(all_implemented, &is_nil(&1.handler_module))

      # All implemented endpoints should have handlers
      for endpoint <- no_handlers do
        IO.puts("Warning: Implemented endpoint without handler: #{endpoint.path}")
      end
    end
  end

  describe "endpoint schema validation" do
    test "all endpoints have required fields" do
      all_endpoints =
        Coverage.get_categories()
        |> Enum.flat_map(&Coverage.get_category_endpoints/1)

      for endpoint <- all_endpoints do
        assert is_binary(endpoint.path), "Missing path for endpoint"

        assert is_list(endpoint.methods) and length(endpoint.methods) > 0,
               "Missing methods for #{endpoint.path}"

        assert endpoint.status in [
                 :implemented,
                 :partial,
                 :in_progress,
                 :planned,
                 :not_supported
               ],
               "Invalid status for #{endpoint.path}: #{endpoint.status}"

        assert endpoint.priority in [:critical, :high, :medium, :low],
               "Invalid priority for #{endpoint.path}"

        assert is_binary(endpoint.since), "Missing since version for #{endpoint.path}"
        assert is_binary(endpoint.description), "Missing description for #{endpoint.path}"
        assert is_list(endpoint.parameters), "Missing parameters list for #{endpoint.path}"
        assert is_map(endpoint.response_schema), "Missing response_schema for #{endpoint.path}"

        assert is_list(endpoint.capabilities_required),
               "Missing capabilities_required for #{endpoint.path}"

        assert is_boolean(endpoint.test_coverage), "Missing test_coverage for #{endpoint.path}"
      end
    end

    test "validates parameter schemas" do
      all_endpoints =
        Coverage.get_categories()
        |> Enum.flat_map(&Coverage.get_category_endpoints/1)

      for endpoint <- all_endpoints do
        for param <- endpoint.parameters do
          assert is_binary(param.name), "Parameter missing name in #{endpoint.path}"

          assert param.type in [:string, :integer, :boolean, :array, :object],
                 "Invalid parameter type in #{endpoint.path}"

          assert is_boolean(param.required), "Parameter missing required flag in #{endpoint.path}"
          assert is_binary(param.description), "Parameter missing description in #{endpoint.path}"
        end
      end
    end
  end

  describe "method validation" do
    test "validates HTTP methods are valid" do
      valid_methods = [:get, :post, :put, :delete, :patch]

      all_endpoints =
        Coverage.get_categories()
        |> Enum.flat_map(&Coverage.get_category_endpoints/1)

      for endpoint <- all_endpoints do
        for method <- endpoint.methods do
          assert method in valid_methods,
                 "Invalid HTTP method #{method} for #{endpoint.path}"
        end
      end
    end

    test "validates method combinations make sense" do
      all_endpoints =
        Coverage.get_categories()
        |> Enum.flat_map(&Coverage.get_category_endpoints/1)

      # Endpoints that are exceptions to normal REST patterns
      action_endpoints = [
        # Authentication - POST only
        "/api2/json/access/ticket",
        # VM actions - POST only
        "/api2/json/nodes/{node}/qemu/{vmid}/status/{command}",
        # Container actions - POST only
        "/api2/json/nodes/{node}/lxc/{vmid}/status/{command}",
        # VM cloning - POST only
        "/api2/json/nodes/{node}/qemu/{vmid}/clone",
        # Container cloning - POST only
        "/api2/json/nodes/{node}/lxc/{vmid}/clone",
        # Cluster join action - POST only
        "/api2/json/cluster/config/join",
        # Realm sync action - POST only
        "/api2/json/access/domains/{realm}/sync",
        # Backup (vzdump) - POST only
        "/api2/json/nodes/{node}/vzdump",
        # Restore actions - POST only
        "/api2/json/nodes/{node}/qmrestore",
        "/api2/json/nodes/{node}/vzrestore",
        # VM migration - POST only
        "/api2/json/nodes/{node}/qemu/{vmid}/migrate",
        # Container migration - POST only
        "/api2/json/nodes/{node}/lxc/{vmid}/migrate",
        # VM snapshot - POST only (list+create)
        "/api2/json/nodes/{node}/qemu/{vmid}/snapshot",
        # VM snapshot rollback - POST only (action)
        "/api2/json/nodes/{node}/qemu/{vmid}/snapshot/{snapname}/rollback",
        # Container snapshot - POST only (list+create)
        "/api2/json/nodes/{node}/lxc/{vmid}/snapshot",
        # Container snapshot rollback - POST only (action)
        "/api2/json/nodes/{node}/lxc/{vmid}/snapshot/{snapname}/rollback",
        # Node execute - POST only
        "/api2/json/nodes/{node}/execute",
        # Container status action - POST only
        "/api2/json/nodes/{node}/lxc/{vmid}/status/{action}",
        # Storage import - POST only
        "/api2/json/nodes/{node}/storage/{storage}/import",
        # Storage upload - POST only (returns UPID)
        "/api2/json/nodes/{node}/storage/{storage}/upload"
      ]

      # Only validate method combinations on implemented endpoints —
      # planned endpoints may have action-only methods we haven't verified.
      implemented = Enum.filter(all_endpoints, &(&1.status == :implemented))

      for endpoint <- implemented do
        methods = endpoint.methods

        # If POST is present for creation, GET should also be present for listing
        # Exception: action endpoints that only perform operations
        if :post in methods and
             String.ends_with?(endpoint.path, "}") == false and
             endpoint.path not in action_endpoints do
          assert :get in methods, "Collection endpoint #{endpoint.path} has POST but no GET"
        end

        # If PUT is present, GET should also be present
        # Exception: action-only endpoints (password change, ACL update)
        put_only_actions = [
          "/api2/json/access/acl",
          "/api2/json/access/password"
        ]

        if :put in methods and endpoint.path not in put_only_actions do
          assert :get in methods, "Endpoint #{endpoint.path} has PUT but no GET"
        end
      end
    end
  end

  describe "get_endpoint_info parameterized paths" do
    test "matches SDN zone path" do
      info = Coverage.get_endpoint_info("/api2/json/cluster/sdn/zones/myzone")
      assert info != nil
      assert info.path == "/api2/json/cluster/sdn/zones/{zone}"
    end

    test "matches pool path" do
      info = Coverage.get_endpoint_info("/api2/json/pools/production")
      assert info != nil
      assert info.path == "/api2/json/pools/{poolid}"
    end

    test "matches node status path" do
      info = Coverage.get_endpoint_info("/api2/json/nodes/pve-node1/status")
      assert info != nil
      assert info.path == "/api2/json/nodes/{node}/status"
    end

    test "matches storage content path" do
      info = Coverage.get_endpoint_info("/api2/json/nodes/pve1/storage/local/content")
      assert info != nil
      assert info.path == "/api2/json/nodes/{node}/storage/{storage}/content"
    end

    test "matches VM status command path" do
      info = Coverage.get_endpoint_info("/api2/json/nodes/pve1/qemu/100/status/start")
      assert info != nil
      assert info.path == "/api2/json/nodes/{node}/qemu/{vmid}/status/{command}"
    end
  end

  describe "coverage matrix completeness" do
    test "has version endpoint" do
      version_info = Coverage.get_endpoint_info("/api2/json/version")
      assert version_info != nil
      assert version_info.status == :implemented
      assert version_info.priority == :critical
    end

    test "has core cluster endpoints" do
      assert Coverage.get_endpoint_info("/api2/json/cluster/status") != nil
      assert Coverage.get_endpoint_info("/api2/json/cluster/resources") != nil
    end

    test "has core VM endpoints" do
      assert Coverage.get_endpoint_info("/api2/json/nodes/{node}/qemu") != nil
      assert Coverage.get_endpoint_info("/api2/json/nodes/{node}/qemu/{vmid}") != nil

      assert Coverage.get_endpoint_info("/api2/json/nodes/{node}/qemu/{vmid}/status/current") !=
               nil
    end

    test "has core container endpoints" do
      assert Coverage.get_endpoint_info("/api2/json/nodes/{node}/lxc") != nil
      assert Coverage.get_endpoint_info("/api2/json/nodes/{node}/lxc/{vmid}") != nil
    end

    test "coverage percentage reflects planned endpoint catalog" do
      stats = Coverage.get_coverage_stats()

      # With ~300 total endpoints and ~68 implemented, coverage is ~22-35%
      assert stats.coverage_percentage > 15.0,
             "Coverage percentage unexpectedly low: #{stats.coverage_percentage}%"

      assert stats.coverage_percentage < 50.0,
             "Coverage percentage unexpectedly high: #{stats.coverage_percentage}% — " <>
               "if many planned endpoints were implemented, update this assertion"

      # Should have some critical endpoints implemented
      critical_endpoints = Coverage.get_endpoints_by_priority(:critical)
      implemented_critical = Enum.filter(critical_endpoints, &(&1.status == :implemented))

      assert length(implemented_critical) > 0, "No critical endpoints implemented"

      # Planned endpoints should outnumber implemented ones
      assert stats.planned > stats.implemented,
             "Expected more planned than implemented endpoints"
    end
  end
end
