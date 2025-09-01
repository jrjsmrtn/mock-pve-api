# Podman Guide for Mock PVE API

This guide provides comprehensive information about using Podman with the Mock PVE API Server, including installation, configuration, best practices, and troubleshooting.

## Overview

[Podman](https://podman.io) is a daemonless, rootless container engine for developing, managing, and running OCI containers. It provides a Docker-compatible interface while offering enhanced security, better resource management, and seamless systemd integration.

## Why Podman over Docker?

### Security Advantages
- **Rootless containers**: Run containers without root privileges for enhanced security
- **No daemon**: No privileged daemon process reducing attack surface  
- **User namespaces**: Better isolation between containers and host
- **SELinux integration**: Enhanced security policies on supported systems

### Resource Management
- **Systemd integration**: Native cgroup management and service integration
- **Pod support**: Kubernetes-like pod concepts for container grouping
- **Better resource accounting**: More accurate resource usage tracking

### Compatibility
- **Docker compatibility**: Drop-in replacement for most Docker commands
- **Kubernetes YAML**: Direct support for Kubernetes pod/deployment YAML
- **OCI compliance**: Full OCI container and image specification compliance

## Installation

### macOS (MacPorts - Preferred)
```bash
# Install Podman via MacPorts
sudo port install podman

# Initialize Podman machine for macOS
podman machine init
podman machine start
```

### macOS (Homebrew Alternative)
```bash
# If MacPorts unavailable, use Homebrew
brew install podman

# Initialize Podman machine
podman machine init
podman machine start
```

### Linux (Ubuntu/Debian)
```bash
# Add Podman repository
curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_$(lsb_release -rs)/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/podman.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/podman.gpg] https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_$(lsb_release -rs)/ /" | sudo tee /etc/apt/sources.list.d/podman.list

# Install Podman
sudo apt update
sudo apt install podman
```

### RHEL/CentOS/Fedora
```bash
# Podman is included in default repositories
sudo dnf install podman

# Or on older systems
sudo yum install podman
```

### Arch Linux
```bash
sudo pacman -S podman
```

## Quick Start with Mock PVE API

### Basic Usage
```bash
# Pull and run Mock PVE API (latest PVE 8.3)
podman run -d --name mock-pve -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest

# Check container status
podman ps

# View logs
podman logs mock-pve

# Stop and remove
podman stop mock-pve
podman rm mock-pve
```

### Rootless Containers (Recommended)
```bash
# Run as regular user (no sudo needed)
podman run -d --name mock-pve-rootless \
  --userns=keep-id \
  -p 8006:8006 \
  docker.io/jrjsmrtn/mock-pve-api:latest

# Verify it's running rootless
podman inspect mock-pve-rootless | jq '.[].HostConfig.UsernsMode'
```

### Configuration Options
```bash
# Run with specific PVE version
podman run -d --name mock-pve-80 \
  -p 8007:8006 \
  -e MOCK_PVE_VERSION=8.0 \
  -e MOCK_PVE_LOG_LEVEL=debug \
  docker.io/jrjsmrtn/mock-pve-api:latest

# Run with custom configuration
podman run -d --name mock-pve-custom \
  -p 8008:8006 \
  -e MOCK_PVE_VERSION=8.3 \
  -e MOCK_PVE_DELAY=100 \
  -e MOCK_PVE_ERROR_RATE=5 \
  docker.io/jrjsmrtn/mock-pve-api:latest
```

## Advanced Usage

### Podman Compose (YAML-based deployment)
```bash
# Create podman-compose.yml
cat > podman-compose.yml << 'EOF'
version: '3.8'
services:
  mock-pve-api:
    image: docker.io/jrjsmrtn/mock-pve-api:latest
    ports:
      - "8006:8006"
    environment:
      - MOCK_PVE_VERSION=8.3
      - MOCK_PVE_LOG_LEVEL=info
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8006/api2/json/version"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

# Start with podman-compose (requires podman-compose plugin)
podman-compose up -d

# Or use Podman with Kubernetes YAML
podman play kube podman-compose.yml
```

### Multiple Version Testing
```bash
# Run multiple PVE versions simultaneously
declare -a versions=("7.4" "8.0" "8.3" "9.0")
for version in "${versions[@]}"; do
  port=$((8000 + ${version%%.*}))
  podman run -d --name "mock-pve-${version}" \
    -p "${port}:8006" \
    -e "MOCK_PVE_VERSION=${version}" \
    docker.io/jrjsmrtn/mock-pve-api:latest
  echo "Started PVE ${version} on port ${port}"
done

# Test all versions
for version in "${versions[@]}"; do
  port=$((8000 + ${version%%.*}))
  echo "Testing PVE ${version} on port ${port}:"
  curl -s "http://localhost:${port}/api2/json/version" | jq '.data.version'
done

# Cleanup all versions
for version in "${versions[@]}"; do
  podman stop "mock-pve-${version}"
  podman rm "mock-pve-${version}"
done
```

### Development with Volume Mounts
```bash
# Mount source code for development
podman run -d --name mock-pve-dev \
  -p 8006:8006 \
  -v "${PWD}:/app:Z" \
  -e MIX_ENV=dev \
  -e MOCK_PVE_LOG_LEVEL=debug \
  docker.io/jrjsmrtn/mock-pve-api:dev

# Interactive development shell
podman exec -it mock-pve-dev /bin/bash
```

## Systemd Integration

### User Service (Rootless)
```bash
# Generate systemd service file
podman generate systemd --new --name mock-pve --files

# Install user service
mkdir -p ~/.config/systemd/user
mv container-mock-pve.service ~/.config/systemd/user/
systemctl --user daemon-reload

# Enable and start service
systemctl --user enable container-mock-pve.service
systemctl --user start container-mock-pve.service

# Check service status
systemctl --user status container-mock-pve.service
```

### System Service (Rootful)
```bash
# Generate system service
sudo podman generate systemd --new --name mock-pve --files
sudo mv container-mock-pve.service /etc/systemd/system/
sudo systemctl daemon-reload

# Enable and start
sudo systemctl enable container-mock-pve.service
sudo systemctl start container-mock-pve.service
```

## Networking

### Basic Port Mapping
```bash
# Map container port 8006 to host port 8006
podman run -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest

# Map to different host port
podman run -p 9006:8006 docker.io/jrjsmrtn/mock-pve-api:latest

# Bind to specific interface
podman run -p 127.0.0.1:8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest
```

### Custom Networks
```bash
# Create custom network
podman network create mock-pve-network

# Run containers on custom network
podman run -d --name mock-pve-1 \
  --network mock-pve-network \
  docker.io/jrjsmrtn/mock-pve-api:latest

podman run -d --name mock-pve-2 \
  --network mock-pve-network \
  -e MOCK_PVE_VERSION=8.0 \
  docker.io/jrjsmrtn/mock-pve-api:latest

# Containers can communicate by name
podman exec mock-pve-1 curl http://mock-pve-2:8006/api2/json/version
```

## Resource Management

### Memory and CPU Limits
```bash
# Set resource limits
podman run -d --name mock-pve-limited \
  --memory=128m \
  --cpus=0.5 \
  -p 8006:8006 \
  docker.io/jrjsmrtn/mock-pve-api:latest

# Monitor resource usage
podman stats mock-pve-limited
```

### Storage Management
```bash
# Use named volumes
podman volume create mock-pve-data
podman run -d --name mock-pve-persistent \
  -v mock-pve-data:/app/data \
  -p 8006:8006 \
  docker.io/jrjsmrtn/mock-pve-api:latest

# Backup volume data
podman run --rm -v mock-pve-data:/data:ro \
  -v "${PWD}:/backup" \
  alpine tar czf /backup/mock-pve-backup.tar.gz -C /data .
```

## CI/CD Integration

### GitHub Actions
```yaml
name: Test with Podman
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      mock-pve:
        image: docker.io/jrjsmrtn/mock-pve-api:latest
        ports:
          - 8006:8006
        options: >-
          --health-cmd "curl -f http://localhost:8006/api2/json/version"
          --health-interval 10s
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Podman
        run: |
          sudo apt-get update
          sudo apt-get install -y podman
          
      - name: Test with Podman
        run: |
          podman run --rm --network host \
            alpine/curl -f http://localhost:8006/api2/json/version
```

### GitLab CI
```yaml
test:
  image: docker.io/alpine/curl
  services:
    - name: docker.io/jrjsmrtn/mock-pve-api:latest
      alias: mock-pve
  script:
    - curl -f http://mock-pve:8006/api2/json/version
```

## Security Best Practices

### Rootless Containers
```bash
# Always prefer rootless when possible
podman run --userns=keep-id docker.io/jrjsmrtn/mock-pve-api:latest

# Check if running rootless
podman info | grep rootless
```

### SELinux Context (Linux)
```bash
# Set proper SELinux context for volumes
podman run -v ./data:/app/data:Z docker.io/jrjsmrtn/mock-pve-api:latest
```

### Read-only Root Filesystem
```bash
# Run with read-only filesystem for security
podman run --read-only --tmpfs /tmp \
  docker.io/jrjsmrtn/mock-pve-api:latest
```

## Troubleshooting

### Common Issues

#### 1. Permission Denied
```bash
# Error: permission denied
# Solution: Use rootless or check file permissions
podman run --userns=keep-id -v "${PWD}:/app:Z" \
  docker.io/jrjsmrtn/mock-pve-api:latest
```

#### 2. Port Already in Use
```bash
# Error: port 8006 already in use
# Solution: Use different port or stop conflicting service
podman run -p 8007:8006 docker.io/jrjsmrtn/mock-pve-api:latest

# Find what's using the port
sudo lsof -i :8006
```

#### 3. Image Pull Issues
```bash
# Error: unable to pull image
# Solution: Check registry connectivity and authentication
podman pull docker.io/jrjsmrtn/mock-pve-api:latest

# Use mirror registry if needed
podman pull quay.io/jrjsmrtn/mock-pve-api:latest
```

#### 4. Container Won't Start
```bash
# Check container logs
podman logs mock-pve

# Inspect container configuration
podman inspect mock-pve

# Run interactively for debugging
podman run -it --rm docker.io/jrjsmrtn/mock-pve-api:latest /bin/bash
```

### Debugging Commands
```bash
# Container information
podman ps -a
podman inspect <container-name>
podman logs <container-name>

# System information
podman info
podman version
podman system info

# Network debugging
podman network ls
podman port <container-name>

# Resource usage
podman stats
podman system df
```

## Migration from Docker

### Command Mapping
```bash
# Docker -> Podman (mostly 1:1)
docker run     -> podman run
docker ps      -> podman ps
docker build   -> podman build
docker pull    -> podman pull
docker exec    -> podman exec
docker logs    -> podman logs
docker stop    -> podman stop
docker rm      -> podman rm

# Compose
docker-compose -> podman-compose
```

### Alias Setup (Optional)
```bash
# Add to ~/.bashrc or ~/.zshrc for seamless transition
alias docker=podman
alias docker-compose=podman-compose

# Or create a more sophisticated alias
docker() {
    echo "Using Podman instead of Docker..."
    podman "$@"
}
```

## Performance Tuning

### Optimization Tips
```bash
# Use specific tags instead of 'latest'
podman run docker.io/jrjsmrtn/mock-pve-api:0.1.0

# Reduce startup time with image cache
podman pull docker.io/jrjsmrtn/mock-pve-api:latest

# Use multi-stage builds for smaller images
# (Already implemented in mock-pve-api)

# Optimize resource allocation
podman run --memory=64m --cpus=0.25 \
  docker.io/jrjsmrtn/mock-pve-api:latest
```

## Additional Resources

### Documentation
- [Podman Official Documentation](https://docs.podman.io/)
- [Podman Tutorial](https://github.com/containers/podman/tree/main/docs/tutorials)
- [Podman Desktop](https://podman-desktop.io/) - GUI for Podman

### Community
- [Podman GitHub Repository](https://github.com/containers/podman)
- [Podman Community](https://podman.io/community/)
- [Container Tools Forum](https://github.com/containers/common/discussions)

### Migration Resources  
- [Docker to Podman Migration Guide](https://docs.podman.io/en/latest/migration.html)
- [Podman vs Docker Comparison](https://docs.podman.io/en/latest/markdown/podman.1.html#comparison-with-other-common-container-engines)

## Conclusion

Podman provides a secure, efficient, and Docker-compatible way to run the Mock PVE API Server. Its rootless architecture, systemd integration, and enhanced security make it an excellent choice for both development and production environments.

For Mock PVE API Server usage, Podman offers:
- **Security**: Rootless containers reduce security risks
- **Performance**: Lower overhead without daemon processes
- **Integration**: Better system service integration
- **Compatibility**: Drop-in replacement for Docker workflows

The Mock PVE API Server is fully tested and optimized for Podman deployment across all supported platforms.