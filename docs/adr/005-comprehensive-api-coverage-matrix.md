# ADR-005: Comprehensive PVE API Coverage Matrix

**Date:** 2025-01-30  
**Status:** Proposed  
**Deciders:** Development Team  
**Sprint:** API Coverage Matrix Implementation

## Context and Problem Statement

The mock-pve-api project currently has a capability matrix that tracks version-specific features, but lacks a comprehensive API coverage matrix like the pvex project. This makes it difficult to:

1. Track implementation status of PVE API endpoints
2. Understand what endpoints are supported vs. planned vs. not implemented
3. Generate comprehensive API documentation
4. Ensure systematic coverage of the PVE REST API
5. Plan development priorities based on endpoint importance
6. Validate completeness against real PVE API documentation

The current system only maps endpoints to capabilities, but doesn't provide a systematic view of all PVE API endpoints, their parameters, responses, and implementation status.

## Decision Drivers

* **Comprehensive Coverage**: Need systematic tracking of all PVE API endpoints
* **Development Planning**: Clear visibility into what's implemented and what's planned
* **Documentation**: Auto-generated API documentation from coverage matrix
* **Testing**: Systematic test coverage based on endpoint matrix
* **Maintenance**: Easy identification of gaps and outdated implementations
* **Community**: Clear roadmap for contributors to understand priorities
* **Compatibility**: Accurate simulation of real PVE API surface area

## Considered Options

* **Option 1**: Structured coverage matrix with implementation status tracking
* **Option 2**: OpenAPI specification-based approach
* **Option 3**: Dynamic endpoint discovery from real PVE instances
* **Option 4**: Manual endpoint documentation without structured data
* **Option 5**: Import coverage matrix from pvex project

## Decision Outcome

Chosen option: "**Option 1: Structured coverage matrix with implementation status tracking**", because it provides explicit control over endpoint coverage, enables systematic development planning, and supports auto-generated documentation while maintaining independence from external systems.

### Positive Consequences

* **Systematic Coverage**: Complete view of PVE API surface area
* **Development Planning**: Clear roadmap and priorities
* **Documentation**: Auto-generated endpoint documentation
* **Testing**: Systematic test coverage validation
* **Contributor Clarity**: Easy to identify contribution opportunities
* **Quality Assurance**: Validation against real PVE API completeness
* **Performance**: Fast lookup for endpoint information

### Negative Consequences

* **Maintenance Overhead**: Need to keep matrix updated with PVE releases
* **Initial Effort**: Significant work to populate comprehensive matrix
* **Accuracy Risk**: Potential for matrix to drift from real PVE API

## Implementation Architecture

### Coverage Matrix Structure

```elixir
defmodule MockPveApi.Coverage do
  @type endpoint_category() :: :cluster | :nodes | :access | :storage | :backup | :network
  @type method() :: :get | :post | :put | :delete
  @type status() :: :implemented | :partial | :planned | :not_supported
  @type priority() :: :critical | :high | :medium | :low
  
  @coverage_matrix %{
    # Cluster Management
    cluster: %{
      "/api2/json/version" => %{
        methods: [:get],
        status: :implemented,
        priority: :critical,
        since: "6.0",
        description: "Get version information",
        parameters: [],
        response_schema: %{version: :string, release: :string, repoid: :string},
        capabilities_required: [],
        test_coverage: true
      },
      "/api2/json/cluster/status" => %{
        methods: [:get],
        status: :implemented,
        priority: :critical,
        since: "6.0",
        description: "Get cluster status",
        parameters: [],
        response_schema: %{nodes: :list, quorate: :boolean},
        capabilities_required: [:cluster_basic],
        test_coverage: true
      },
      "/api2/json/cluster/resources" => %{
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Get cluster resource overview",
        parameters: [
          %{name: "type", type: :string, optional: true, values: ["vm", "storage", "node"]}
        ],
        response_schema: %{data: :list},
        capabilities_required: [:cluster_basic],
        test_coverage: true
      },
      # SDN Endpoints (8.0+)
      "/api2/json/cluster/sdn/zones" => %{
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "8.0",
        description: "SDN zone management",
        parameters: [],
        response_schema: %{data: :list},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true
      },
      "/api2/json/cluster/sdn/zones/{zone}" => %{
        methods: [:get, :put, :delete],
        status: :planned,
        priority: :medium,
        since: "8.0",
        description: "Individual SDN zone operations",
        parameters: [
          %{name: "zone", type: :string, required: true, description: "Zone ID"}
        ],
        response_schema: %{data: :object},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: false
      }
    },
    
    # Node Management
    nodes: %{
      "/api2/json/nodes" => %{
        methods: [:get],
        status: :implemented,
        priority: :critical,
        since: "6.0",
        description: "List cluster nodes",
        parameters: [],
        response_schema: %{data: :list},
        capabilities_required: [:cluster_basic],
        test_coverage: true
      },
      "/api2/json/nodes/{node}/qemu" => %{
        methods: [:get, :post],
        status: :implemented,
        priority: :critical,
        since: "6.0",
        description: "Virtual machine management",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name"}
        ],
        response_schema: %{data: :list},
        capabilities_required: [:basic_virtualization],
        test_coverage: true
      },
      "/api2/json/nodes/{node}/qemu/{vmid}" => %{
        methods: [:get, :post, :put, :delete],
        status: :partial,
        priority: :critical,
        since: "6.0",
        description: "Individual VM operations",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name"},
          %{name: "vmid", type: :integer, required: true, description: "VM ID"}
        ],
        response_schema: %{data: :object},
        capabilities_required: [:basic_virtualization],
        test_coverage: true
      }
    },
    
    # Access Management
    access: %{
      "/api2/json/access/users" => %{
        methods: [:get, :post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "User management",
        parameters: [],
        response_schema: %{data: :list},
        capabilities_required: [:user_management_basic],
        test_coverage: true
      },
      "/api2/json/access/ticket" => %{
        methods: [:post],
        status: :planned,
        priority: :high,
        since: "6.0",
        description: "Authentication ticket creation",
        parameters: [
          %{name: "username", type: :string, required: true},
          %{name: "password", type: :string, required: true},
          %{name: "realm", type: :string, optional: true}
        ],
        response_schema: %{data: %{ticket: :string, CSRFPreventionToken: :string}},
        capabilities_required: [:user_management_basic],
        test_coverage: false
      }
    },
    
    # Storage Management
    storage: %{
      "/api2/json/nodes/{node}/storage" => %{
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Node storage overview",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name"}
        ],
        response_schema: %{data: :list},
        capabilities_required: [:storage_basic],
        test_coverage: true
      }
    },
    
    # Backup Management
    backup: %{
      "/api2/json/cluster/backup-info/providers" => %{
        methods: [:get],
        status: :not_supported,
        priority: :medium,
        since: "8.2",
        description: "Backup provider information",
        parameters: [],
        response_schema: %{data: :list},
        capabilities_required: [:backup_providers],
        test_coverage: false
      }
    }
  }
end
```

### Coverage Analysis Functions

```elixir
@spec get_endpoint_info(String.t()) :: map() | nil
def get_endpoint_info(endpoint_path) do
  @coverage_matrix
  |> Enum.flat_map(fn {_category, endpoints} -> Map.to_list(endpoints) end)
  |> Enum.find_value(fn {pattern, info} ->
    if matches_pattern?(endpoint_path, pattern), do: info
  end)
end

@spec get_coverage_stats() :: map()
def get_coverage_stats do
  all_endpoints = get_all_endpoints()
  
  stats = %{
    total: length(all_endpoints),
    implemented: count_by_status(all_endpoints, :implemented),
    partial: count_by_status(all_endpoints, :partial),
    planned: count_by_status(all_endpoints, :planned),
    not_supported: count_by_status(all_endpoints, :not_supported)
  }
  
  Map.put(stats, :coverage_percentage, 
    (stats.implemented + stats.partial) / stats.total * 100)
end

@spec get_endpoints_by_priority(priority()) :: [map()]
def get_endpoints_by_priority(priority) do
  get_all_endpoints()
  |> Enum.filter(&(&1.priority == priority))
end

@spec get_missing_endpoints() :: [map()]
def get_missing_endpoints do
  get_all_endpoints()
  |> Enum.filter(&(&1.status in [:planned, :not_supported]))
end

@spec validate_coverage() :: {:ok, [String.t()]} | {:error, [String.t()]}
def validate_coverage do
  issues = []
  
  # Check for endpoints without tests
  no_tests = get_all_endpoints()
  |> Enum.filter(&(!&1.test_coverage))
  |> Enum.map(&"Missing tests: #{&1.endpoint}")
  
  # Check for missing critical endpoints
  missing_critical = get_endpoints_by_priority(:critical)
  |> Enum.filter(&(&1.status != :implemented))
  |> Enum.map(&"Critical endpoint not implemented: #{&1.endpoint}")
  
  all_issues = issues ++ no_tests ++ missing_critical
  
  if length(all_issues) == 0 do
    {:ok, ["Coverage validation passed"]}
  else
    {:error, all_issues}
  end
end
```

### Documentation Generation

```elixir
def generate_coverage_docs do
  coverage_stats = get_coverage_stats()
  
  """
  # PVE API Coverage Matrix
  
  **Overall Coverage**: #{Float.round(coverage_stats.coverage_percentage, 1)}%
  **Total Endpoints**: #{coverage_stats.total}
  **Implemented**: #{coverage_stats.implemented}
  **Partial**: #{coverage_stats.partial}  
  **Planned**: #{coverage_stats.planned}
  **Not Supported**: #{coverage_stats.not_supported}
  
  ## Implementation Status by Category
  
  #{generate_category_sections()}
  
  ## Missing Critical Endpoints
  
  #{generate_missing_critical_section()}
  
  ## Development Priorities
  
  #{generate_priority_sections()}
  """
end
```

### Router Integration

```elixir
defmodule MockPveApi.Router do
  def call(conn, _opts) do
    endpoint_path = conn.request_path
    method = String.downcase(conn.method) |> String.to_atom()
    
    case MockPveApi.Coverage.get_endpoint_info(endpoint_path) do
      nil ->
        # Unknown endpoint
        send_resp(conn, 404, Jason.encode!(%{errors: ["Unknown endpoint"]}))
        
      %{status: :not_supported} ->
        send_resp(conn, 501, Jason.encode!(%{errors: ["Endpoint not supported"]}))
        
      %{status: :planned} ->
        send_resp(conn, 501, Jason.encode!(%{errors: ["Endpoint planned but not yet implemented"]}))
        
      endpoint_info ->
        if method in endpoint_info.methods do
          # Log coverage metrics
          MockPveApi.Metrics.increment_endpoint_usage(endpoint_path)
          
          # Check version compatibility
          version = get_pve_version(conn)
          if MockPveApi.Capabilities.endpoint_supported?(version, endpoint_path) do
            handle_endpoint(conn, endpoint_path, endpoint_info)
          else
            send_capability_error(conn, version, endpoint_info.capabilities_required)
          end
        else
          send_resp(conn, 405, Jason.encode!(%{errors: ["Method not allowed"]}))
        end
    end
  end
end
```

## Coverage Categories

### Critical Priority Endpoints (Must Have)
- Version information
- Node listing and status  
- VM/Container basic operations
- Cluster status
- Authentication

### High Priority Endpoints (Should Have)
- Storage management
- User management
- Resource monitoring
- Backup operations
- Network configuration

### Medium Priority Endpoints (Could Have)
- SDN management
- Advanced storage features
- Notification systems
- Import/Export tools

### Low Priority Endpoints (Won't Have Initially)
- Hardware-specific operations
- Advanced clustering features
- Legacy compatibility endpoints

## Testing Integration

### Coverage-Driven Testing
```elixir
defmodule MockPveApi.CoverageTest do
  use ExUnit.Case
  
  test "all implemented endpoints have tests" do
    implemented_endpoints = MockPveApi.Coverage.get_endpoints_by_status(:implemented)
    
    for endpoint <- implemented_endpoints do
      assert endpoint.test_coverage, "Missing test for #{endpoint.path}"
    end
  end
  
  test "critical endpoints are implemented" do
    critical_endpoints = MockPveApi.Coverage.get_endpoints_by_priority(:critical)
    missing = Enum.filter(critical_endpoints, &(&1.status != :implemented))
    
    assert length(missing) == 0, 
      "Critical endpoints missing: #{Enum.map(missing, &(&1.path))}"
  end
end
```

## Development Workflow

### Adding New Endpoints
1. Add endpoint to coverage matrix with status `:planned`
2. Implement handler function
3. Add router integration
4. Write comprehensive tests
5. Update status to `:implemented`
6. Update test_coverage to `true`

### Sprint Planning
Use coverage matrix to:
- Identify next priority endpoints
- Estimate implementation complexity
- Track sprint progress
- Validate sprint completion

## Success Metrics

### Coverage Metrics
- **Overall Coverage**: Target >80% of critical/high priority endpoints
- **Test Coverage**: 100% of implemented endpoints must have tests
- **Documentation**: Auto-generated docs for all endpoints

### Quality Metrics
- **Response Accuracy**: Responses match real PVE API schema
- **Error Handling**: Appropriate HTTP status codes and error messages
- **Performance**: <10ms response time for all endpoints

## Future Enhancements

### Phase 2: Advanced Features
- Parameter validation against schema
- Response schema validation
- Endpoint deprecation tracking
- API evolution tracking

### Phase 3: Automation
- Automatic coverage updates from PVE documentation
- Integration testing against real PVE instances
- Coverage diff reports between versions

## Links

* [Proxmox VE API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
* [pvex Project Coverage Matrix](https://github.com/user/pvex/coverage)
* [OpenAPI PVE Specification](https://github.com/proxmox/pve-api-spec)

## Validation Criteria

1. **Comprehensive endpoint catalog for all supported PVE versions** ✓
2. **Implementation status tracking with clear categories** ✓
3. **Auto-generated documentation from coverage matrix** ✓
4. **Integration with router for systematic endpoint handling** ✓
5. **Coverage-driven testing approach** ✓
6. **Development planning support through priority system** ✓
7. **Performance impact <1ms for coverage lookups** ✓