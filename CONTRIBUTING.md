# Contributing to Mock PVE API

Thank you for your interest in contributing to Mock PVE API! This document provides guidelines and information for contributors.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it before contributing.

## Getting Started

### Development Setup

1. **Prerequisites**:
   - Elixir 1.15+ and OTP 26+
   - Docker and Docker Compose
   - Git

2. **Clone and Setup**:
   ```bash
   git clone https://github.com/jrjsmrtn/mock-pve-api.git
   cd mock-pve-api
   mix deps.get
   mix compile
   ```

3. **Run Tests**:
   ```bash
   mix test
   mix test --cover  # With coverage
   ```

4. **Start Development Server**:
   ```bash
   mix run --no-halt
   # Or with Docker
   docker-compose up mock-pve-dev
   ```

### Project Structure

```
lib/
├── mock_pve_api.ex              # Main application entry
├── mock_pve_api/
│   ├── application.ex           # OTP Application
│   ├── router.ex                # HTTP routing
│   ├── capabilities.ex          # Version-specific features
│   ├── state.ex                 # Resource state management
│   ├── fixtures.ex              # JSON response fixtures
│   └── handlers/                # API endpoint handlers
config/                          # Environment configuration
docker/                          # Docker configurations
test/                           # Test files
examples/                       # Usage examples
```

## How to Contribute

### Reporting Issues

1. **Check existing issues** to avoid duplicates
2. **Use issue templates** for bug reports and feature requests
3. **Provide clear details**:
   - Environment (Docker, local, etc.)
   - PVE version being simulated
   - Steps to reproduce
   - Expected vs actual behavior
   - Relevant logs or error messages

### Submitting Changes

1. **Fork the repository**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Add tests** for new functionality
5. **Update documentation** if needed
6. **Commit with clear messages**:
   ```bash
   git commit -m "Add support for PVE backup provider endpoints"
   ```
7. **Push and create a pull request**

### Pull Request Guidelines

- **Use the PR template** and fill out all relevant sections
- **Keep PRs focused** - one feature/fix per PR
- **Write descriptive titles** and descriptions
- **Reference related issues** using `Closes #123` or `Related to #456`
- **Ensure all tests pass** locally before submitting
- **Update CHANGELOG.md** for significant changes

## Development Guidelines

### Code Style

- **Follow Elixir conventions** and use `mix format`
- **Write clear, descriptive function names**
- **Add typespecs** for public functions
- **Include module documentation** with `@moduledoc`
- **Document public functions** with `@doc`

Example:
```elixir
@doc """
Handles version endpoint requests for the specified PVE version.

Returns version information including release, version number, and
available features based on the configured PVE version.

## Examples

    iex> MockPveApi.Handlers.Version.handle(conn, %{"version" => "8.3"})
    %{data: %{version: "8.3", release: "8.3-1", ...}}
"""
@spec handle(Plug.Conn.t(), map()) :: Plug.Conn.t()
def handle(conn, params) do
  # Implementation
end
```

### Testing

- **Write tests** for all new functionality
- **Test different PVE versions** when applicable
- **Include integration tests** for API endpoints
- **Mock external dependencies** appropriately
- **Aim for >90% test coverage**

Example test:
```elixir
describe "version endpoint" do
  test "returns correct version for PVE 8.3" do
    conn = build_conn(:get, "/api2/json/version")
    |> put_pve_version("8.3")
    |> MockPveApi.Router.call([])

    assert %{"data" => %{"version" => "8.3"}} = json_response(conn, 200)
  end

  test "includes SDN capabilities for PVE 8.0+" do
    conn = build_conn(:get, "/api2/json/version")
    |> put_pve_version("8.0")
    |> MockPveApi.Router.call([])

    response = json_response(conn, 200)
    assert response["data"]["capabilities"]["sdn"] == true
  end
end
```

### Adding New API Endpoints

1. **Research the real PVE API**:
   - Check Proxmox documentation
   - Test against actual PVE instances when possible
   - Note version-specific behavior

2. **Create handler module**:
   ```elixir
   defmodule MockPveApi.Handlers.NewEndpoint do
     @moduledoc """
     Handles /api2/json/new/endpoint requests.
     """

     def handle(conn, params) do
       # Implementation
     end
   end
   ```

3. **Add route** in `router.ex`:
   ```elixir
   get "/api2/json/new/endpoint", NewEndpoint, :handle
   ```

4. **Add capability checks** if version-specific:
   ```elixir
   def handle(conn, params) do
     version = get_pve_version(conn)
     
     unless MockPveApi.Capabilities.supports?(version, :new_feature) do
       send_error(conn, 501, "Feature not available in PVE #{version}")
     else
       # Handle request
     end
   end
   ```

5. **Create fixtures** for different versions
6. **Write comprehensive tests**

### Adding PVE Version Support

1. **Update capabilities matrix** in `capabilities.ex`:
   ```elixir
   "9.1" => [
     # All previous capabilities
     :basic_virtualization,
     # ... existing capabilities ...
     :new_9_1_feature
   ]
   ```

2. **Add version-specific fixtures** if needed
3. **Update documentation** and version support matrix
4. **Add tests** for version-specific behavior

### Docker Improvements

- **Keep images minimal** - use multi-stage builds
- **Support multiple architectures** (amd64, arm64)
- **Add health checks** for container orchestration
- **Use semantic versioning** for image tags
- **Document environment variables**

### Documentation

- **Update README.md** for user-facing changes
- **Update CHANGELOG.md** for all changes
- **Add examples** for new features
- **Include Docker usage** examples
- **Document environment variables**

## Release Process

1. **Version bump** in `mix.exs`
2. **Update CHANGELOG.md** with release notes
3. **Tag release**: `git tag -a v0.2.0 -m "Version 0.2.0"`
4. **Push tag**: `git push origin v0.2.0`
5. **GitHub Actions** will build and publish Docker images
6. **Create GitHub release** with release notes

## Testing Locally

### Unit Tests
```bash
mix test                    # All tests
mix test --cover           # With coverage
mix test test/specific_test.exs  # Specific test file
```

### Integration Testing
```bash
# Start mock server
mix run --no-halt &

# Test endpoints
curl http://localhost:8006/api2/json/version
curl http://localhost:8006/api2/json/nodes

# Stop server
pkill -f "mix run"
```

### Docker Testing
```bash
# Build and test locally
docker build -f docker/Dockerfile -t mock-pve-api:local .
docker run -d -p 8006:8006 mock-pve-api:local

# Test different versions
docker run -d -p 8007:8006 -e MOCK_PVE_VERSION=7.4 mock-pve-api:local
curl http://localhost:8007/api2/json/version
```

## Getting Help

- **Join discussions** in GitHub Discussions
- **Ask questions** in issues with the "question" label  
- **Check existing documentation** and examples
- **Look at similar implementations** in the codebase

## Recognition

Contributors will be recognized in:
- **CHANGELOG.md** for significant contributions
- **README.md** contributors section
- **GitHub contributors** graph

Thank you for contributing to Mock PVE API! 🚀