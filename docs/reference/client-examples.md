# Client Examples Reference

This reference provides details on all available client implementations for testing the Mock PVE API Server across different programming languages.

## Available Languages

### Python (`python/test_client.py`)
Complete Python client example with detailed API testing.

**Features:**
- Version information retrieval
- Cluster status and resource listing
- Node management testing
- Version-specific feature detection
- Comprehensive error handling

**Dependencies:**
```bash
pip install requests
```

**Usage:**
```bash
python examples/python/test_client.py
```

---

### JavaScript/Node.js (`javascript/test-client.js`)
Node.js client example using axios for HTTP requests.

**Features:**
- Async/await pattern usage
- Resource enumeration and analysis
- Version compatibility checking
- Error handling with proper logging

**Dependencies:**
```bash
npm install axios
```

**Usage:**
```bash
node examples/javascript/test-client.js
```

---

### Elixir (`elixir/test_client.exs`)
Native Elixir client example showcasing idiomatic patterns.

**Features:**
- HTTPoison for HTTP requests
- Pattern matching for response handling
- Version comparison with Elixir Version module
- Comprehensive error handling

**Dependencies:**
Dependencies managed by the test script.

**Usage:**
```bash
elixir examples/elixir/test_client.exs
```

---

### Go (`go/test-client.go`)
Go client example with strong typing and error handling.

**Features:**
- Structured data types for API responses
- Comprehensive error handling
- Type-safe JSON parsing
- Clean separation of concerns

**Dependencies:**
Go modules handle dependencies automatically.

**Usage:**
```bash
go run examples/go/test-client.go
```

---

### Ruby (`ruby/test_client.rb`)
Ruby client example using HTTParty gem.

**Features:**
- HTTParty for simplified HTTP requests
- Clean Ruby idioms and patterns
- Version comparison logic
- Graceful error handling

**Dependencies:**
```bash
gem install httparty json
```

**Usage:**
```bash
ruby examples/ruby/test_client.rb
```

---

### Shell Script (`shell/test-endpoints.sh`)
Bash script using curl and jq for API testing.

**Features:**
- Works with standard shell tools
- Optional jq integration for JSON parsing
- Comprehensive endpoint coverage
- CI/CD friendly output

**Dependencies:**
- curl (standard on most systems)
- jq (optional, for JSON parsing)

**Usage:**
```bash
chmod +x examples/shell/test-endpoints.sh
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

| Variable | Default | Description |
|----------|---------|-------------|
| `PVE_HOST` | `localhost` | Mock server hostname |
| `PVE_PORT` | `8006` | Mock server port |

**Example:**
```bash
export PVE_HOST=localhost
export PVE_PORT=8006
python examples/python/test_client.py
```

## Expected Output Format

All examples produce similar structured output:

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

## Error Handling Examples

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

## CI/CD Integration Examples

### GitHub Actions
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

### Multi-Version Testing Script
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

## Creating Custom Examples

### Guidelines

When creating examples for other languages:

1. **Follow the common pattern**: Version → Cluster → Resources → Features
2. **Handle errors gracefully**: Check for connection issues and API errors
3. **Support environment configuration**: PVE_HOST and PVE_PORT variables
4. **Include version-specific testing**: Check feature availability
5. **Provide clear output**: Use emojis and formatting for readability
6. **Add documentation**: Include usage instructions and requirements

### Directory Structure Template
```
examples/
├── <language>/
│   ├── client.ext              # Main client implementation
│   ├── requirements.txt        # Dependencies (if applicable)
│   ├── README.md              # Language-specific instructions
│   └── example-output.txt     # Sample output
```

### Required Functions

Each example should implement these core functions:

1. **Connection Test**: Verify server is reachable
2. **Version Detection**: Get PVE version and capabilities  
3. **Resource Enumeration**: List VMs, containers, nodes, storage
4. **Feature Testing**: Test version-specific endpoints
5. **Error Handling**: Graceful error handling and reporting

### Response Processing

Examples should handle these PVE API response patterns:

**Success Response:**
```json
{
  "data": { /* response data */ }
}
```

**Error Response:**
```json
{
  "errors": ["error message"]
}
```

**Version-Specific Error:**
```json
{
  "errors": [
    "Feature not implemented",
    "SDN features require PVE 8.0+, currently simulating 7.4"
  ]
}
```

## Testing Examples

### Automated Testing
```bash
# Test all examples against running mock server
make test-examples

# Start mock server and run integration tests
make test-integration
```

### Manual Testing
```bash
# Start mock server
podman run -d --name mock-pve -p 8006:8006 \
  -e MOCK_PVE_VERSION=8.3 \
  docker.io/jrjsmrtn/mock-pve-api:latest

# Wait for server to be ready
sleep 3

# Test each language
python examples/python/test_client.py
node examples/javascript/test-client.js
elixir examples/elixir/test_client.exs
go run examples/go/test-client.go
ruby examples/ruby/test_client.rb
./examples/shell/test-endpoints.sh

# Cleanup
podman stop mock-pve && podman rm mock-pve
```

## Version Compatibility Testing

All examples support testing against different PVE versions:

```bash
# Test PVE 7.4 features
MOCK_PVE_VERSION=7.4 podman run -d --name mock-pve-74 \
  -p 8074:8006 \
  -e MOCK_PVE_VERSION=7.4 \
  docker.io/jrjsmrtn/mock-pve-api:latest

PVE_PORT=8074 python examples/python/test_client.py

# Test PVE 8.3 features
MOCK_PVE_VERSION=8.3 podman run -d --name mock-pve-83 \
  -p 8083:8006 \
  -e MOCK_PVE_VERSION=8.3 \
  docker.io/jrjsmrtn/mock-pve-api:latest

PVE_PORT=8083 python examples/python/test_client.py
```

## Contributing Examples

We welcome examples in additional languages! Requirements:

1. Follow the established patterns and output format
2. Include proper error handling and environment variable support
3. Test against multiple PVE versions to ensure compatibility
4. Add comprehensive documentation and usage instructions
5. Submit a pull request with your example

---

*These examples are tested against the Mock PVE API Server to ensure accuracy and are kept up-to-date with the latest API changes.*