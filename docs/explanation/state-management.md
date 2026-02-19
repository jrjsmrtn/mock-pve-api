# State Management Architecture

This document explains how the Mock PVE API Server manages simulated resources and maintains consistent state across concurrent requests. Understanding the state management system is crucial for contributors and users who want to understand the server's behavior.

## Overview

The Mock PVE API Server simulates a complete Proxmox VE environment including nodes, virtual machines, containers, storage, resource pools, and user accounts. All this state must be maintained consistently while serving multiple concurrent API requests from different clients.

## Core Design Principles

### 1. Centralized State Management

All resource state is managed by a single GenServer process (`MockPveApi.State`) that serializes access and ensures consistency.

### 2. In-Memory Storage

State is kept entirely in memory for fast access and simple deployment without external dependencies.

### 3. Process Isolation

HTTP requests are handled in separate processes, isolating failures and preventing one request from affecting others.

### 4. Atomic Operations

State changes are atomic - either they succeed completely or fail without partial updates.

## State Architecture

### State GenServer Structure

```elixir
# MockPveApi.State GenServer holds all simulated resources
%{
  version: "8.3",                    # Current PVE version being simulated
  capabilities: %{                   # Feature availability matrix
    sdn: true,
    backup_providers: true,
    notifications: true
  },

  # Infrastructure Resources
  nodes: %{
    "pve-node-1" => %{
      status: "online",
      cpu: 0.15,
      memory: %{used: 2147483648, total: 8589934592},
      uptime: 86400,
      pve_version: "8.3-1"
    }
  },

  # Compute Resources
  vms: %{
    100 => %{
      vmid: 100,
      name: "test-vm",
      node: "pve-node-1",
      status: "running",
      cpu: 0.25,
      memory: 2147483648,
      config: %{cores: 2, memory: 2048}
    }
  },

  containers: %{
    200 => %{
      vmid: 200,
      name: "test-container",
      node: "pve-node-1",
      status: "running",
      cpu: 0.10,
      memory: 1073741824,
      config: %{cores: 1, memory: 1024}
    }
  },

  # Storage Resources
  storage: %{
    "local" => %{
      storage: "local",
      type: "dir",
      node: "pve-node-1",
      content: ["images", "vztmpl", "backup"],
      used: 21474836480,
      total: 107374182400
    }
  },

  # Organization Resources
  pools: %{
    "production" => %{
      poolid: "production",
      comment: "Production environment",
      members: [
        %{type: "qemu", vmid: 100, node: "pve-node-1"},
        %{type: "lxc", vmid: 200, node: "pve-node-1"}
      ]
    }
  },

  # Access Control
  users: %{
    "root@pam" => %{
      userid: "root@pam",
      enable: 1,
      comment: "Built-in Superuser"
    }
  },

  groups: %{
    "administrators" => %{
      groupid: "administrators",
      members: ["root@pam"]
    }
  },

  # Version-Specific Features (PVE 8.0+)
  sdn: %{
    zones: %{
      "localnetwork" => %{
        zone: "localnetwork",
        type: "simple",
        nodes: ["pve-node-1"]
      }
    },
    vnets: %{
      "vnet100" => %{
        vnet: "vnet100",
        zone: "localnetwork",
        tag: 100
      }
    }
  }
}
```

### State Access Patterns

#### Read Operations

```elixir
# Get all VMs on a specific node
def get_node_vms(node_name) do
  GenServer.call(__MODULE__, {:get_node_vms, node_name})
end

# Implementation in GenServer
def handle_call({:get_node_vms, node_name}, _from, state) do
  vms =
    state.vms
    |> Enum.filter(fn {_id, vm} -> vm.node == node_name end)
    |> Enum.map(fn {_id, vm} -> vm end)

  {:reply, vms, state}
end
```

#### Write Operations

```elixir
# Create new VM
def create_vm(vm_config) do
  GenServer.call(__MODULE__, {:create_vm, vm_config})
end

# Implementation with validation and state update
def handle_call({:create_vm, config}, _from, state) do
  with :ok <- validate_vm_config(config),
       :ok <- check_vmid_available(state, config.vmid) do

    vm = %{
      vmid: config.vmid,
      name: config.name,
      node: config.node,
      status: "stopped",
      config: config
    }

    new_state = put_in(state.vms[config.vmid], vm)
    {:reply, {:ok, vm}, new_state}
  else
    error -> {:reply, error, state}
  end
end
```

## Resource Lifecycle Management

### Virtual Machine Lifecycle

```elixir
# VM states and transitions
@vm_states [:stopped, :running, :paused, :suspended]

# State transition validations
def validate_state_transition(current_state, target_state) do
  case {current_state, target_state} do
    {:stopped, :running} -> :ok        # Start VM
    {:running, :stopped} -> :ok        # Stop VM
    {:running, :paused} -> :ok         # Pause VM
    {:paused, :running} -> :ok         # Resume VM
    {:running, :suspended} -> :ok      # Suspend VM
    {:suspended, :running} -> :ok      # Resume from suspend
    _ -> {:error, :invalid_transition}
  end
end

# VM operation with state transition
def start_vm(vmid) do
  GenServer.call(__MODULE__, {:start_vm, vmid})
end

def handle_call({:start_vm, vmid}, _from, state) do
  case get_in(state.vms, [vmid]) do
    nil -> {:reply, {:error, :not_found}, state}
    vm ->
      case validate_state_transition(vm.status, :running) do
        :ok ->
          updated_vm = %{vm | status: :running, uptime: 0}
          new_state = put_in(state.vms[vmid], updated_vm)
          task_id = generate_task_id("qmstart", vmid)
          {:reply, {:ok, task_id}, new_state}

        error -> {:reply, error, state}
      end
  end
end
```

### Resource ID Management

```elixir
# Ensure unique IDs for VMs and containers
def allocate_next_vmid(state) do
  used_ids =
    (Map.keys(state.vms) ++ Map.keys(state.containers))
    |> MapSet.new()

  # Find next available ID starting from 100
  Stream.iterate(100, &(&1 + 1))
  |> Enum.find(&(not MapSet.member?(used_ids, &1)))
end

# Validate resource references
def validate_pool_members(state, members) do
  Enum.all?(members, fn member ->
    case member do
      %{type: "qemu", vmid: vmid} -> Map.has_key?(state.vms, vmid)
      %{type: "lxc", vmid: vmid} -> Map.has_key?(state.containers, vmid)
      _ -> false
    end
  end)
end
```

## Concurrency and Consistency

### Request Isolation

Each HTTP request is handled in a separate Elixir process:

```elixir
# Request handling flow
HTTP Request → Cowboy Process → Handler Module → GenServer Call → Response

# Example: Multiple concurrent VM operations
# Process 1: GET /nodes/pve-node-1/qemu
# Process 2: POST /nodes/pve-node-1/qemu (create VM)
# Process 3: POST /nodes/pve-node-1/qemu/100/status/start

# All processes serialize through the same GenServer
```

### Atomic State Updates

```elixir
# Complex operation: Move VM between pools
def move_vm_between_pools(vmid, from_pool, to_pool) do
  GenServer.call(__MODULE__, {:move_vm_pools, vmid, from_pool, to_pool})
end

def handle_call({:move_vm_pools, vmid, from_pool, to_pool}, _from, state) do
  with {:ok, vm} <- get_vm(state, vmid),
       {:ok, from_pool_data} <- get_pool(state, from_pool),
       {:ok, to_pool_data} <- get_pool(state, to_pool) do

    # Atomic update: remove from one pool, add to another
    member = %{type: "qemu", vmid: vmid, node: vm.node}

    updated_from_pool = %{
      from_pool_data |
      members: List.delete(from_pool_data.members, member)
    }

    updated_to_pool = %{
      to_pool_data |
      members: [member | to_pool_data.members]
    }

    new_state = state
                |> put_in([:pools, from_pool], updated_from_pool)
                |> put_in([:pools, to_pool], updated_to_pool)

    {:reply, :ok, new_state}
  else
    error -> {:reply, error, state}
  end
end
```

### Error Handling and Recovery

```elixir
# State recovery from invalid operations
def handle_call({:invalid_operation, params}, _from, state) do
  Logger.warn("Invalid operation attempted: #{inspect(params)}")
  {:reply, {:error, :invalid_operation}, state}  # State unchanged
end

# Graceful degradation for missing resources
def get_vm_safe(state, vmid) do
  case Map.get(state.vms, vmid) do
    nil -> {:error, :not_found}
    vm -> {:ok, vm}
  end
end
```

## State Initialization

### Default State Setup

```elixir
defmodule MockPveApi.State do
  def init(_args) do
    version = Application.get_env(:mock_pve_api, :pve_version, "8.3")

    initial_state = %{
      version: version,
      capabilities: MockPveApi.Capabilities.get_capabilities(version),
      nodes: create_default_nodes(),
      vms: create_default_vms(),
      containers: create_default_containers(),
      storage: create_default_storage(),
      pools: %{},
      users: create_default_users(),
      groups: create_default_groups()
    }

    # Add version-specific resources
    final_state = case supports_sdn?(version) do
      true -> Map.put(initial_state, :sdn, create_default_sdn())
      false -> initial_state
    end

    {:ok, final_state}
  end

  defp create_default_nodes do
    %{
      "pve-node-1" => %{
        node: "pve-node-1",
        status: "online",
        cpu: 0.15,
        maxcpu: 8,
        mem: 2147483648,
        maxmem: 8589934592,
        uptime: 86400
      }
    }
  end
end
```

### State Reset Functionality

```elixir
# Reset state to initial configuration (useful for testing)
def reset_state do
  GenServer.call(__MODULE__, :reset_state)
end

def handle_call(:reset_state, _from, _current_state) do
  {:ok, new_state} = init([])
  {:reply, :ok, new_state}
end
```

## Performance Considerations

### Memory Management

```elixir
# Monitor state size and prevent unbounded growth
def handle_call({:get_state_size}, _from, state) do
  size_info = %{
    nodes: map_size(state.nodes),
    vms: map_size(state.vms),
    containers: map_size(state.containers),
    storage: map_size(state.storage),
    pools: map_size(state.pools),
    total_memory: :erlang.system_info(:total_memory)
  }
  {:reply, size_info, state}
end

# Limit resource creation to prevent memory exhaustion
@max_resources 1000

def create_resource_with_limit(state, resource_type, resource_data) do
  current_count = count_resources(state, resource_type)

  if current_count >= @max_resources do
    {:error, :resource_limit_exceeded}
  else
    create_resource(state, resource_type, resource_data)
  end
end
```

### State Compression

```elixir
# Remove unnecessary data from state
def cleanup_state(state) do
  %{
    state |
    # Remove old completed tasks
    tasks: filter_recent_tasks(state.tasks),
    # Compact VM history
    vms: compact_vm_history(state.vms)
  }
end
```

## Testing State Management

### State Assertions

```elixir
defmodule MockPveApi.StateTest do
  use ExUnit.Case

  test "VM creation updates state correctly" do
    # Create VM
    {:ok, task_id} = State.create_vm(%{
      vmid: 999,
      name: "test-vm-999",
      node: "pve-node-1"
    })

    # Verify state
    {:ok, vm} = State.get_vm(999)
    assert vm.vmid == 999
    assert vm.name == "test-vm-999"
    assert vm.status == "stopped"
  end

  test "concurrent VM operations maintain consistency" do
    # Spawn multiple processes creating VMs
    tasks = for i <- 1..10 do
      Task.async(fn ->
        State.create_vm(%{vmid: 1000 + i, name: "concurrent-#{i}"})
      end)
    end

    # Wait for all to complete
    results = Task.await_many(tasks)

    # All should succeed
    assert Enum.all?(results, &match?({:ok, _}, &1))

    # Verify all VMs exist
    vms = State.list_vms()
    concurrent_vms = Enum.filter(vms, &String.starts_with?(&1.name, "concurrent-"))
    assert length(concurrent_vms) == 10
  end
end
```

### State Validation

```elixir
# Validate state consistency
def validate_state(state) do
  with :ok <- validate_node_references(state),
       :ok <- validate_resource_ids(state),
       :ok <- validate_pool_memberships(state),
       :ok <- validate_version_compatibility(state) do
    :ok
  else
    error -> error
  end
end

def validate_node_references(state) do
  # Ensure all VMs and containers reference valid nodes
  invalid_refs =
    (Map.values(state.vms) ++ Map.values(state.containers))
    |> Enum.reject(fn resource -> Map.has_key?(state.nodes, resource.node) end)

  case invalid_refs do
    [] -> :ok
    refs -> {:error, {:invalid_node_references, refs}}
  end
end
```

## Troubleshooting State Issues

### State Inspection Tools

```bash
# Get current state summary via API
curl http://localhost:8006/api2/json/_debug/state/summary

# Get detailed resource counts
curl http://localhost:8006/api2/json/_debug/state/resources

# Reset state to initial configuration
curl -X POST http://localhost:8006/api2/json/_debug/state/reset
```

### Common State Problems

1. **Resource Not Found**: Check if resource was created and IDs match
2. **State Inconsistency**: Verify atomic operations and error handling
3. **Memory Growth**: Monitor resource creation and implement limits
4. **Concurrent Access Issues**: Ensure all state access goes through GenServer

### Debugging State Changes

```elixir
# Add logging to state operations
def handle_call({:create_vm, config}, from, state) do
  Logger.info("Creating VM: #{inspect(config)} from #{inspect(from)}")

  result = create_vm_impl(config, state)

  Logger.info("VM creation result: #{inspect(result)}")

  result
end
```

---

_The state management system is designed to be simple, consistent, and testable. When extending functionality, maintain these principles to ensure reliable operation across all use cases._

