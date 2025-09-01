# Your First PVE API Test

This tutorial will guide you through creating your first test using the Mock PVE API Server. You'll learn the basic patterns for testing PVE client code.

## What You'll Learn

By the end of this tutorial, you'll understand:
- How to start the mock server
- How to authenticate with the PVE API
- How to make basic API calls
- How to interpret API responses

## Prerequisites

- You've completed the [Getting Started](getting-started.md) tutorial
- Mock PVE API server is running on `localhost:8006`

## Step 1: Test Server Connection

First, let's verify the server is running and responsive:

```bash
# Check server version
curl http://localhost:8006/api2/json/version

# Expected response:
{
  "data": {
    "version": "8.3",
    "release": "8.3",
    "keyboard": "en-us",
    "repoid": "f123456d"
  }
}
```

**Understanding the Response:**
- All PVE API responses are wrapped in a `"data"` object
- The version tells you which PVE features are available
- No authentication is required for the version endpoint

## Step 2: Get an Authentication Ticket

Most PVE API endpoints require authentication. Let's get a ticket:

```bash
curl -X POST http://localhost:8006/api2/json/access/ticket \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=root@pam&password=secret"
```

**Response:**
```json
{
  "data": {
    "ticket": "PVEAuthCookie=...",
    "username": "root@pam", 
    "CSRFPreventionToken": "..."
  }
}
```

**Key Concepts:**
- The mock server accepts any username/password combination
- The ticket is used for subsequent authenticated requests
- Real PVE would validate credentials against configured realms

## Step 3: Make Authenticated API Calls

Now use the ticket to access protected endpoints:

```bash
# Extract the ticket (save this for reuse)
TICKET="your-ticket-from-above"

# List cluster nodes
curl -H "Authorization: PVEAuthCookie=$TICKET" \
  http://localhost:8006/api2/json/nodes

# Check cluster status  
curl -H "Authorization: PVEAuthCookie=$TICKET" \
  http://localhost:8006/api2/json/cluster/status
```

## Step 4: Understanding API Responses

PVE API responses follow consistent patterns:

**Success Response:**
```json
{
  "data": [
    {
      "node": "pve-node1",
      "status": "online",
      "cpu": 0.15,
      "mem": 8589934592
    }
  ]
}
```

**Error Response:**
```json
{
  "errors": {
    "message": "authentication failure"
  }
}
```

## Step 5: Testing Different PVE Versions

The mock server can simulate different PVE versions. Restart with a different version:

```bash
# Stop current container
podman stop mock-pve-api

# Start with PVE 7.4
podman run -d --name mock-pve-74 -p 8007:8006 \
  -e MOCK_PVE_VERSION=7.4 mock-pve-api:latest

# Test version-specific behavior
curl http://localhost:8007/api2/json/version
curl -H "Authorization: PVEAuthCookie=$TICKET" \
  http://localhost:8007/api2/json/cluster/sdn/zones  # Should fail on 7.4
```

## Next Steps

Now that you understand the basics, you can:

1. **Try Language-Specific Examples**: Check out [Client Examples](../reference/client-examples.md)
2. **Learn Advanced Testing**: See [Multi-Version Testing](../how-to/multi-version-testing.md)  
3. **Integrate with CI/CD**: Follow [CI/CD Setup](../how-to/setup-ci-cd.md)

## Common Issues

**Connection Refused:**
- Ensure the container is running: `podman ps`
- Check port mapping: should see `0.0.0.0:8006->8006/tcp`

**Authentication Failures:**
- Check ticket format: should start with PVEAuthCookie=
- Tickets expire - get a new one if requests start failing

**Unexpected Responses:**
- Check PVE version: different versions support different features
- Verify endpoint URL: must start with `/api2/json/`