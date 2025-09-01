# Mock PVE API - Examples

This directory contains example client implementations in various programming languages that demonstrate how to use the Mock PVE API Server for testing and development.

## Available Examples

### Python (`python/test_client.py`)
Complete Python client example with detailed API testing.

**Features:**
- Version information retrieval
- Cluster status and resource listing
- Node management testing
- Version-specific feature detection
- Comprehensive error handling

**Usage:**
```bash
# Install requirements
pip install requests

# Run example (with mock server running)
python examples/python/test_client.py
```

### JavaScript/Node.js (`javascript/test-client.js`)
Node.js client example using axios for HTTP requests.

**Features:**
- Async/await pattern usage
- Resource enumeration and analysis
- Version compatibility checking
- Error handling with proper logging

**Usage:**
```bash
# Install requirements
npm install axios

# Run example
node examples/javascript/test-client.js
```

### Elixir (`elixir/test_client.exs`)
Native Elixir client example showcasing idiomatic patterns.

**Features:**
- HTTPoison for HTTP requests
- Pattern matching for response handling
- Version comparison with Elixir Version module
- Comprehensive error handling

**Usage:**
```bash
# Dependencies managed by the test script
elixir examples/elixir/test_client.exs
```

### Go (`go/test-client.go`)
Go client example with strong typing and error handling.

**Features:**
- Structured data types for API responses
- Comprehensive error handling
- Type-safe JSON parsing
- Clean separation of concerns

**Usage:**
```bash
# Run directly (Go modules handle dependencies)
go run examples/go/test-client.go
```

### Ruby (`ruby/test_client.rb`)
Ruby client example using HTTParty gem.

**Features:**
- HTTParty for simplified HTTP requests
- Clean Ruby idioms and patterns
- Version comparison logic
- Graceful error handling

**Usage:**
```bash
# Install requirements
gem install httparty json

# Run example
ruby examples/ruby/test_client.rb
```

### Shell Script (`shell/test-endpoints.sh`)
Bash script using curl and jq for API testing.

**Features:**
- Works with standard shell tools
- Optional jq integration for JSON parsing
- Comprehensive endpoint coverage
- CI/CD friendly output

**Usage:**
```bash
# Make executable (if needed)
chmod +x examples/shell/test-endpoints.sh

# Run with jq for best experience
./examples/shell/test-endpoints.sh
```

## Common Testing Pattern

All examples follow a consistent testing pattern:

1. **Version Information**: Get PVE version and capabilities
2. **Cluster Status**: Check cluster health and node status  
3. **Resource Listing**: Enumerate VMs, containers, and storage
4. **Feature Testing**: Test version-specific features (SDN, backup providers)
5. **Error Handling**: Demonstrate proper error handling

## Configuration

All examples support environment variable configuration:

```bash
# Configure target host/port
export PVE_HOST=localhost
export PVE_PORT=8006

# Run any example
python examples/python/test_client.py
```

## Starting Mock Server

Before running examples, start the Mock PVE API Server:

```bash
# Default PVE 8.3 simulation
podman run -d -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest

# Or specific version
podman run -d -p 8006:8006 \
  -e MOCK_PVE_VERSION=8.0 \
  docker.io/jrjsmrtn/mock-pve-api:latest
```

## Example Output

All examples produce similar output:

```
🚀 Mock PVE API Client Test (Python)
========================================

🔍 Testing version information...
  ✅ PVE Version: 8.3
  ✅ Release: 8.3-1
  ✅ Repository ID: abcd1234

🔍 Testing cluster status...
  ✅ Cluster: mock-cluster
  ✅ Node: pve-node-1 - Status: online

🔍 Testing nodes list...
  ✅ Node: pve-node-1 - Status: online
     CPU: 15.0% - Memory: 2.0GB

🔍 Testing cluster resources...
  ✅ VM 100: test-vm - Status: running
  ✅ CT 200: test-container - Status: running
  ✅ Storage: local - Type: dir

📊 Resource Summary:
     qemu: 1
     lxc: 1
     storage: 2
     node: 1

🔍 Testing version-specific features for PVE 8.3...
  🔍 Testing SDN zones (PVE 8.0+)...
  ✅ SDN Zones: 1 zones available
  🔍 Testing backup providers (PVE 8.2+)...
  ✅ Backup Providers: 2 providers available

========================================
🎉 All tests completed successfully!

Mock PVE API Server is working correctly.
```

## Error Scenarios

Examples demonstrate proper error handling:

### Connection Refused
```
❌ Error: Could not connect to Mock PVE API Server

Make sure the server is running:
  podman run -d -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest
```

### Version-Specific Features
```
🔍 Testing version-specific features for PVE 7.4...
  ⏭️  SDN features not available in PVE 7.4
  ⏭️  Backup providers not available in PVE 7.4
```

### API Errors (501 Not Implemented)
```
⚠️ SDN endpoints test failed: HTTP 501: 
{
  "errors": [
    "Feature not implemented", 
    "SDN features require PVE 8.0+, currently simulating 7.4"
  ]
}
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Test PVE Client
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      mock-pve:
        image: docker.io/jrjsmrtn/mock-pve-api:latest
        ports: ["8006:8006"]
        env:
          MOCK_PVE_VERSION: "8.3"

    strategy:
      matrix:
        language: [python, javascript, ruby]

    steps:
      - uses: actions/checkout@v4
      
      - name: Test Python client
        if: matrix.language == 'python'
        run: |
          pip install requests
          python examples/python/test_client.py
          
      - name: Test JavaScript client  
        if: matrix.language == 'javascript'
        run: |
          npm install axios
          node examples/javascript/test-client.js
          
      - name: Test Ruby client
        if: matrix.language == 'ruby'  
        run: |
          gem install httparty json
          ruby examples/ruby/test_client.rb
```

### Multi-Version Testing

```bash
#!/bin/bash
# Test against multiple PVE versions

versions=("7.4" "8.0" "8.3" "9.0")

for version in "${versions[@]}"; do
  echo "Testing PVE $version..."
  
  # Start version-specific container
  podman run -d --name mock-pve-$version \
    -p 800$((${version%%.*})):8006 \
    -e MOCK_PVE_VERSION=$version \
    docker.io/jrjsmrtn/mock-pve-api:latest
  
  sleep 3
  
  # Test with Python client
  PVE_PORT=800$((${version%%.*})) \
    python examples/python/test_client.py
  
  # Cleanup
  podman stop mock-pve-$version
  podman rm mock-pve-$version
done
```

## Creating Your Own Examples

When creating examples for other languages:

1. **Follow the common pattern**: Version → Cluster → Resources → Features
2. **Handle errors gracefully**: Check for connection issues and API errors
3. **Support environment configuration**: PVE_HOST and PVE_PORT variables
4. **Include version-specific testing**: Check feature availability
5. **Provide clear output**: Use emojis and formatting for readability
6. **Add documentation**: Include usage instructions and requirements

### Template Structure
```
examples/
├── <language>/
│   ├── client.ext              # Main client implementation
│   ├── requirements.txt        # Dependencies (if applicable)
│   ├── README.md              # Language-specific instructions
│   └── example-output.txt     # Sample output
```

## Testing the Examples

Use the provided Makefile for automated testing:

```bash
# Test all examples against running mock server
make test-examples

# Start mock server and run integration tests
make test-integration
```

## Contributing Examples

We welcome examples in additional languages! Please:

1. Follow the established patterns and output format
2. Include proper error handling and environment variable support
3. Test against multiple PVE versions to ensure compatibility
4. Add comprehensive documentation and usage instructions
5. Submit a pull request with your example

## Related Documentation

- **[Getting Started Guide](../docs/guides/getting-started.md)**: Basic usage patterns
- **[API Reference](../docs/guides/api-reference.md)**: Complete endpoint documentation
- **[CI/CD Integration](../docs/guides/ci-cd-integration.md)**: Advanced CI/CD patterns
- **[Architecture](../architecture/README.md)**: System architecture documentation

---

*These examples are tested against the Mock PVE API Server to ensure accuracy and are kept up-to-date with the latest API changes.*