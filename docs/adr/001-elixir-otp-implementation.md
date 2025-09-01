# ADR-001: Elixir/OTP for Mock Server Implementation

**Date:** 2025-01-30  
**Status:** Accepted  
**Deciders:** Development Team

## Context and Problem Statement

Mock PVE API Server needs to handle concurrent HTTP requests from multiple clients while maintaining consistent state for simulated resources (VMs, containers, storage). The choice of implementation language and runtime affects performance, reliability, and maintainability. What technology stack should we use for the mock server implementation?

## Decision Drivers

* **Concurrency Requirements**: Handle multiple simultaneous API requests efficiently
* **State Management**: Maintain consistent state across concurrent operations
* **Fault Tolerance**: Graceful handling of errors without affecting other operations
* **Memory Efficiency**: Lightweight processes for resource simulation
* **Code Maintainability**: Clear, readable code with strong typing support
* **Ecosystem Compatibility**: Easy integration with existing Elixir tools (pvex origin)
* **Container Footprint**: Small container size for deployment flexibility

## Considered Options

* **Option 1**: Elixir/OTP with GenServer state management
* **Option 2**: Node.js with Express and in-memory state
* **Option 3**: Go with goroutines and channels for state
* **Option 4**: Python with FastAPI and asyncio
* **Option 5**: Java Spring Boot with concurrent collections

## Decision Outcome

Chosen option: "**Option 1: Elixir/OTP with GenServer state management**", because it provides the best combination of concurrency, fault tolerance, and maintainability for a mock server that needs to handle multiple clients while maintaining consistent state.

### Positive Consequences

* **Excellent Concurrency**: Actor model handles thousands of concurrent connections efficiently
* **Built-in Fault Tolerance**: OTP supervision trees provide automatic error recovery
* **State Consistency**: GenServer ensures serialized access to shared state
* **Low Memory Footprint**: Lightweight processes use minimal memory
* **Pattern Matching**: Excellent for handling different API request types
* **Hot Code Reloading**: Easy development and deployment updates
* **Strong Community**: Mature ecosystem with proven libraries (Plug, Cowboy)

### Negative Consequences

* **Learning Curve**: Functional programming paradigm may be unfamiliar to some contributors
* **Specialized Knowledge**: Smaller developer pool compared to mainstream languages
* **Startup Time**: BEAM VM startup slightly slower than native binaries
* **Binary Size**: Erlang runtime included in container images

## Pros and Cons of the Options

### Option 1: Elixir/OTP with GenServer

* Good, because Actor model naturally handles concurrent API requests
* Good, because GenServer provides built-in state management and serialization
* Good, because OTP supervision trees offer automatic fault recovery
* Good, because pattern matching simplifies request routing and response generation
* Good, because Plug ecosystem provides HTTP handling without full framework overhead
* Good, because originated from pvex project - familiar technology
* Bad, because requires Elixir knowledge from contributors
* Bad, because BEAM VM adds container size overhead

### Option 2: Node.js with Express

* Good, because widely known technology with large developer community
* Good, because JSON handling is natural and efficient
* Good, because npm ecosystem provides many useful libraries
* Good, because fast startup time and development cycle
* Bad, because single-threaded nature limits true concurrency
* Bad, because shared mutable state requires careful locking mechanisms
* Bad, because no built-in supervision/fault tolerance

### Option 3: Go with goroutines

* Good, because excellent performance and low memory usage
* Good, because goroutines provide efficient concurrency
* Good, because static compilation produces small, fast binaries
* Good, because strong typing and tooling
* Bad, because more complex state management with channels/mutexes
* Bad, because less natural for HTTP API simulation
* Bad, because verbose error handling

### Option 4: Python with FastAPI

* Good, because easy to understand and contribute to
* Good, because FastAPI provides automatic API documentation
* Good, because rich ecosystem for testing and mocking
* Bad, because GIL limits true concurrency
* Bad, because runtime dependencies increase container size
* Bad, because performance limitations under high load

### Option 5: Java Spring Boot

* Good, because mature ecosystem and enterprise-grade features
* Good, because excellent tooling and IDE support
* Good, because built-in concurrent collections
* Bad, because heavy framework overhead for a mock server
* Bad, because large memory footprint and startup time
* Bad, because verbose code for simple API mocking

## Implementation Details

### Core Architecture
```elixir
# Supervision tree structure
MockPveApi.Application
├── MockPveApi.State (GenServer) - Resource state management
└── Plug.Cowboy - HTTP server with MockPveApi.Router
```

### State Management Strategy
```elixir
# GenServer state structure
%{
  version: "8.3",
  nodes: %{...},
  vms: %{...},
  containers: %{...},
  storage: %{...},
  pools: %{...}
}
```

### Concurrency Benefits
- **Request Isolation**: Each HTTP request handled in separate process
- **State Serialization**: GenServer ensures consistent state updates
- **Fault Tolerance**: Failed requests don't affect server stability
- **Resource Efficiency**: Lightweight processes scale to thousands of connections

## Links

* [Elixir GenServer Documentation](https://hexdocs.pm/elixir/GenServer.html)
* [OTP Supervision Trees](https://hexdocs.pm/elixir/supervisors-and-applications.html)
* [Plug HTTP Library](https://hexdocs.pm/plug/)
* [Cowboy HTTP Server](https://ninenines.eu/docs/en/cowboy/2.9/guide/)

## Validation

This decision can be validated by:
1. **Performance Testing**: Measuring concurrent request handling capacity
2. **Memory Usage**: Monitoring memory consumption under load
3. **Fault Tolerance**: Testing error recovery scenarios
4. **Development Velocity**: Measuring time to implement new features
5. **Container Metrics**: Comparing image size and startup time with alternatives