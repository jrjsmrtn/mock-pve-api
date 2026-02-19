# How to Integrate with Existing PVE Clients

This guide shows you how to integrate the Mock PVE API Server with existing Proxmox client libraries and applications for testing.

## Problem Solved

You have existing code that uses PVE client libraries (proxmoxer, pvex, proxmox-api-go, etc.) and want to test it without requiring a real Proxmox VE cluster.

## Quick Solution

Point your existing client to the mock server by changing the host/port configuration:

```python
# Before: Real PVE cluster
from proxmoxer import ProxmoxAPI
pve = ProxmoxAPI('pve.example.com', user='root@pam', password='secret', verify_ssl=False)

# After: Mock server  
pve = ProxmoxAPI('localhost', port=8006, user='root@pam', password='secret', verify_ssl=False)
```

## Language-Specific Integration

### Python (proxmoxer)

```python
# test_with_proxmoxer.py
import pytest
from proxmoxer import ProxmoxAPI
from proxmoxer.backends import https

def test_existing_pve_code():
    # Your existing PVE client code
    pve = ProxmoxAPI(
        'localhost',  # Changed from real PVE host
        port=8006,    # Mock server port
        user='root@pam', 
        password='secret',
        verify_ssl=False
    )
    
    # Your existing business logic - no changes needed!
    version = pve.version.get()
    assert 'version' in version
    
    nodes = pve.nodes.get()
    assert isinstance(nodes, list)
    assert len(nodes) >= 1
    
    # Test VM operations
    vm_config = {
        'vmid': 100,
        'name': 'test-vm',
        'memory': 2048,
        'cores': 2
    }
    
    # Create VM (same API as real PVE)
    task = pve.nodes('pve-node1').qemu.post(**vm_config)
    assert 'UPID' in task  # Task ID returned
    
    # List VMs 
    vms = pve.nodes('pve-node1').qemu.get()
    assert any(vm['vmid'] == 100 for vm in vms)
```

### JavaScript/Node.js (custom client)

```javascript
// test_existing_client.js
const axios = require('axios');

class PVEClient {
    constructor(host, port = 8006, user = 'root@pam', password = 'secret') {
        this.baseURL = `http://${host}:${port}/api2/json`;
        this.user = user;
        this.password = password;
        this.ticket = null;
    }
    
    async authenticate() {
        const response = await axios.post(`${this.baseURL}/access/ticket`, 
            `username=${this.user}&password=${this.password}`,
            { headers: { 'Content-Type': 'application/x-www-form-urlencoded' }}
        );
        this.ticket = response.data.data.ticket;
        return this.ticket;
    }
    
    async get(endpoint) {
        if (!this.ticket) await this.authenticate();
        
        const response = await axios.get(`${this.baseURL}${endpoint}`, {
            headers: { 'Authorization': `PVEAuthCookie=${this.ticket}` }
        });
        return response.data.data;
    }
}

// Your existing test code - just change the host
async function testExistingLogic() {
    const pve = new PVEClient('localhost', 8006);  // Point to mock server
    
    // Your existing business logic
    const version = await pve.get('/version');
    console.log('PVE Version:', version.version);
    
    const nodes = await pve.get('/nodes');
    console.log('Available nodes:', nodes.length);
    
    const clusterStatus = await pve.get('/cluster/status'); 
    console.log('Cluster nodes:', clusterStatus.length);
}

testExistingLogic().catch(console.error);
```

### Elixir (pvex)

```elixir
# test/integration_test.exs
defmodule MyApp.PVEIntegrationTest do
  use ExUnit.Case
  
  # Your existing PVE integration code
  defp setup_pve_client do
    # Change from real cluster to mock server
    Pvex.new(
      host: "localhost",     # Changed from real host
      port: 8006,           # Mock server port  
      username: "root@pam",
      password: "secret",
      verify_ssl: false
    )
  end
  
  test "existing pve operations work with mock server" do
    client = setup_pve_client()
    
    # Your existing business logic - no changes!
    {:ok, version} = Pvex.get(client, "/version")
    assert version["data"]["version"] =~ ~r/\d+\.\d+/
    
    {:ok, nodes} = Pvex.get(client, "/nodes")  
    assert is_list(nodes["data"])
    assert length(nodes["data"]) >= 1
    
    # Test authenticated operations
    {:ok, status} = Pvex.get(client, "/cluster/status")
    assert is_list(status["data"])
  end
  
  test "vm management with existing code" do
    client = setup_pve_client()
    
    # Your existing VM creation logic
    vm_config = %{
      vmid: 101,
      name: "test-vm-elixir", 
      memory: 1024,
      cores: 1
    }
    
    {:ok, task} = Pvex.post(client, "/nodes/pve-node1/qemu", vm_config)
    assert String.contains?(task["data"], "UPID")
    
    # Verify VM was created
    {:ok, vms} = Pvex.get(client, "/nodes/pve-node1/qemu")
    assert Enum.any?(vms["data"], fn vm -> vm["vmid"] == 101 end)
  end
end
```

### Go (custom client)

```go
// main_test.go
package main

import (
    "testing"
    "encoding/json"
    "net/http"
    "strings"
    "fmt"
)

type PVEClient struct {
    BaseURL string
    Ticket  string
    Client  *http.Client
}

func NewPVEClient(host string, port int) *PVEClient {
    return &PVEClient{
        BaseURL: fmt.Sprintf("http://%s:%d/api2/json", host, port),
        Client:  &http.Client{},
    }
}

func (c *PVEClient) Authenticate(username, password string) error {
    data := fmt.Sprintf("username=%s&password=%s", username, password)
    resp, err := c.Client.Post(c.BaseURL+"/access/ticket", 
        "application/x-www-form-urlencoded",
        strings.NewReader(data))
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    
    var result map[string]interface{}
    json.NewDecoder(resp.Body).Decode(&result)
    c.Ticket = result["data"].(map[string]interface{})["ticket"].(string)
    return nil
}

// Your existing PVE client methods work unchanged
func (c *PVEClient) Get(endpoint string) (map[string]interface{}, error) {
    req, _ := http.NewRequest("GET", c.BaseURL+endpoint, nil)
    req.Header.Add("Authorization", "PVEAuthCookie="+c.Ticket)
    
    resp, err := c.Client.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    var result map[string]interface{}
    json.NewDecoder(resp.Body).Decode(&result)
    return result, nil
}

func TestExistingPVELogic(t *testing.T) {
    // Point to mock server instead of real cluster
    client := NewPVEClient("localhost", 8006)
    
    err := client.Authenticate("root@pam", "secret")
    if err != nil {
        t.Fatalf("Authentication failed: %v", err)
    }
    
    // Your existing business logic
    version, err := client.Get("/version")
    if err != nil {
        t.Fatalf("Failed to get version: %v", err)
    }
    
    versionStr := version["data"].(map[string]interface{})["version"].(string)
    if versionStr == "" {
        t.Error("Version should not be empty")
    }
    
    // Test node listing
    nodes, err := client.Get("/nodes")
    if err != nil {
        t.Fatalf("Failed to get nodes: %v", err)  
    }
    
    nodeList := nodes["data"].([]interface{})
    if len(nodeList) < 1 {
        t.Error("Should have at least one node")
    }
}
```

## Configuration Patterns

### Environment-Based Configuration

Make your client configurable via environment variables:

```python
# config.py  
import os

class PVEConfig:
    def __init__(self):
        self.host = os.getenv('PVE_HOST', 'pve.example.com')
        self.port = int(os.getenv('PVE_PORT', '8006'))  
        self.user = os.getenv('PVE_USER', 'root@pam')
        self.password = os.getenv('PVE_PASSWORD', 'secret')
        self.verify_ssl = os.getenv('PVE_VERIFY_SSL', 'true').lower() == 'true'

# Usage for production
config = PVEConfig()  # Uses real cluster

# Usage for testing  
os.environ['PVE_HOST'] = 'localhost'
os.environ['PVE_PORT'] = '8006'  
os.environ['PVE_VERIFY_SSL'] = 'false'
config = PVEConfig()  # Uses mock server
```

### Test Configuration Fixture

```python
# conftest.py
import pytest
import subprocess
import time
import os

@pytest.fixture(scope="session")
def mock_pve_server():
    """Start mock server for testing session"""
    # Start container
    container_id = subprocess.check_output([
        'podman', 'run', '-d', 
        '--name', 'pytest-mock-pve',
        '-p', '8006:8006',
        '-e', 'MOCK_PVE_VERSION=8.3',
        'mock-pve-api:latest'
    ]).decode().strip()
    
    # Wait for ready
    for _ in range(30):
        try:
            import requests
            resp = requests.get('http://localhost:8006/api2/json/version', timeout=2)
            if resp.status_code == 200:
                break
        except:
            time.sleep(1)
    
    # Configure environment for tests
    original_host = os.environ.get('PVE_HOST')
    original_port = os.environ.get('PVE_PORT')
    
    os.environ['PVE_HOST'] = 'localhost'
    os.environ['PVE_PORT'] = '8006'
    
    yield
    
    # Cleanup
    subprocess.run(['podman', 'stop', 'pytest-mock-pve'], check=False)
    subprocess.run(['podman', 'rm', 'pytest-mock-pve'], check=False)
    
    # Restore environment
    if original_host:
        os.environ['PVE_HOST'] = original_host
    if original_port:
        os.environ['PVE_PORT'] = original_port
```

## Testing Real vs Mock Behavior

Sometimes you need to verify mock behavior matches real PVE:

```python
# test_parity.py
import pytest
from proxmoxer import ProxmoxAPI

@pytest.fixture(params=[
    {'host': 'real-pve.example.com', 'port': 8006, 'type': 'real'},
    {'host': 'localhost', 'port': 8006, 'type': 'mock'}
])
def pve_client(request):
    config = request.param
    return {
        'client': ProxmoxAPI(config['host'], port=config['port'], 
                           user='root@pam', password='secret', verify_ssl=False),
        'type': config['type']
    }

def test_api_parity(pve_client):
    """Test that mock and real PVE return similar responses"""
    client = pve_client['client']
    client_type = pve_client['type']
    
    # Test version endpoint
    version = client.version.get()
    assert 'version' in version
    assert 'release' in version
    
    # Response structure should be identical
    if client_type == 'real':
        # Record real response structure for comparison
        pass
    else:
        # Verify mock matches real structure  
        pass
```

## Migration Checklist

When integrating existing code with mock server:

- [ ] **Change host/port configuration** to point to mock server
- [ ] **Disable SSL verification** (mock server uses HTTP)
- [ ] **Update authentication** if needed (mock accepts any credentials)
- [ ] **Environment variables** for test vs production configuration
- [ ] **Container lifecycle** management in test setup/teardown
- [ ] **Feature detection** for version-specific functionality
- [ ] **Test data isolation** to avoid conflicts
- [ ] **Error handling** for mock-specific responses

## Common Pitfalls

**SSL/TLS Issues:**
- Mock server uses HTTP, not HTTPS
- Disable SSL verification in your client

**Authentication Assumptions:**
- Mock server accepts any username/password
- Real PVE validates against configured realms

**Resource State:**
- Mock server starts with clean state
- Your tests might expect existing resources

**Version Differences:**
- Mock server simulates specific versions
- Real PVE might have different patch levels or customizations