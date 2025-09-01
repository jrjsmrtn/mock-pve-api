#!/bin/bash
# setup-podman.sh - Podman Setup Script for Mock PVE API Server
# 
# This script helps users install Podman and set up the Mock PVE API Server
# with optimal configuration for development and testing.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_VERSION="0.1.0"
MOCK_PVE_IMAGE="docker.io/jrjsmrtn/mock-pve-api:latest"
DEFAULT_PORT=8006
SETUP_MODE="interactive"

# Usage information
usage() {
    cat << EOF
Mock PVE API - Podman Setup Script v${SCRIPT_VERSION}

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --version           Show script version
    -q, --quiet             Quiet mode (minimal output)
    -y, --yes               Non-interactive mode (auto-confirm)
    -p, --port PORT         Set port for Mock PVE API (default: ${DEFAULT_PORT})
    --install-only          Only install Podman, don't run Mock PVE API
    --run-only              Only run Mock PVE API (assume Podman installed)
    --cleanup               Stop and remove Mock PVE API containers

EXAMPLES:
    $0                      Interactive setup with default options
    $0 -y                   Non-interactive setup
    $0 -p 8007              Setup with Mock PVE API on port 8007
    $0 --cleanup            Stop and remove all Mock PVE containers
    $0 --install-only       Only install Podman
    $0 --run-only           Only setup and run Mock PVE API

This script will:
1. Detect your operating system
2. Install Podman if not present
3. Configure Podman for optimal performance
4. Pull and run Mock PVE API Server
5. Verify the installation works correctly
EOF
}

# Logging functions
log_info() {
    if [[ "${SETUP_MODE}" != "quiet" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_success() {
    if [[ "${SETUP_MODE}" != "quiet" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    fi
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# System detection
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

detect_package_manager() {
    local os=$1
    case $os in
        "macos")
            if command -v port >/dev/null 2>&1; then
                echo "macports"
            elif command -v brew >/dev/null 2>&1; then
                echo "homebrew"
            else
                echo "none"
            fi
            ;;
        "ubuntu"|"debian")
            echo "apt"
            ;;
        "fedora"|"rhel"|"centos")
            if command -v dnf >/dev/null 2>&1; then
                echo "dnf"
            else
                echo "yum"
            fi
            ;;
        "arch")
            echo "pacman"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Installation functions
install_podman_macports() {
    log_info "Installing Podman via MacPorts..."
    sudo port install podman
}

install_podman_homebrew() {
    log_info "Installing Podman via Homebrew..."
    brew install podman
}

install_podman_apt() {
    log_info "Installing Podman via APT..."
    
    # Add Podman repository for Ubuntu/Debian
    local version
    version=$(lsb_release -rs)
    
    curl -fsSL "https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${version}/Release.key" | \
        sudo gpg --dearmor -o /etc/apt/keyrings/podman.gpg
    
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/podman.gpg] https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${version}/ /" | \
        sudo tee /etc/apt/sources.list.d/podman.list >/dev/null
    
    sudo apt update
    sudo apt install -y podman
}

install_podman_dnf() {
    log_info "Installing Podman via DNF..."
    sudo dnf install -y podman
}

install_podman_yum() {
    log_info "Installing Podman via YUM..."
    sudo yum install -y podman
}

install_podman_pacman() {
    log_info "Installing Podman via Pacman..."
    sudo pacman -S --noconfirm podman
}

# Check if Podman is already installed
check_podman() {
    if command -v podman >/dev/null 2>&1; then
        local version
        version=$(podman --version | cut -d' ' -f3)
        log_success "Podman is already installed (version: ${version})"
        return 0
    else
        log_info "Podman not found, installation required"
        return 1
    fi
}

# Install Podman based on OS and package manager
install_podman() {
    local os package_manager
    os=$(detect_os)
    package_manager=$(detect_package_manager "$os")
    
    log_info "Detected OS: $os"
    log_info "Package manager: $package_manager"
    
    case $package_manager in
        "macports")
            install_podman_macports
            ;;
        "homebrew")
            install_podman_homebrew
            ;;
        "apt")
            install_podman_apt
            ;;
        "dnf")
            install_podman_dnf
            ;;
        "yum")
            install_podman_yum
            ;;
        "pacman")
            install_podman_pacman
            ;;
        *)
            log_error "Unsupported package manager: $package_manager"
            log_error "Please install Podman manually: https://podman.io/getting-started/installation"
            exit 1
            ;;
    esac
}

# Configure Podman for macOS
configure_podman_macos() {
    log_info "Configuring Podman for macOS..."
    
    # Initialize Podman machine if needed
    if ! podman machine list | grep -q "Currently running"; then
        log_info "Initializing Podman machine..."
        podman machine init --memory 2048 --disk-size 20 2>/dev/null || true
        podman machine start
    fi
}

# Configure Podman
configure_podman() {
    local os
    os=$(detect_os)
    
    case $os in
        "macos")
            configure_podman_macos
            ;;
        *)
            log_info "Podman configuration complete for $os"
            ;;
    esac
}

# Verify Podman installation
verify_podman() {
    log_info "Verifying Podman installation..."
    
    # Check Podman version
    if ! podman --version >/dev/null 2>&1; then
        log_error "Podman installation failed"
        exit 1
    fi
    
    # Test basic functionality
    if ! podman info >/dev/null 2>&1; then
        log_error "Podman is installed but not functioning correctly"
        exit 1
    fi
    
    log_success "Podman installation verified"
}

# Pull Mock PVE API image
pull_mock_pve_image() {
    log_info "Pulling Mock PVE API Server image..."
    podman pull "$MOCK_PVE_IMAGE"
    log_success "Mock PVE API Server image pulled"
}

# Stop existing Mock PVE containers
stop_existing_containers() {
    log_info "Stopping existing Mock PVE containers..."
    
    # Find and stop containers based on image name
    local containers
    containers=$(podman ps -q --filter "ancestor=$MOCK_PVE_IMAGE" 2>/dev/null || true)
    
    if [[ -n "$containers" ]]; then
        echo "$containers" | xargs podman stop 2>/dev/null || true
        log_success "Stopped existing containers"
    fi
    
    # Also stop any containers with mock-pve in the name
    containers=$(podman ps -q --filter "name=mock-pve" 2>/dev/null || true)
    if [[ -n "$containers" ]]; then
        echo "$containers" | xargs podman stop 2>/dev/null || true
    fi
}

# Run Mock PVE API Server
run_mock_pve_api() {
    local port=${1:-$DEFAULT_PORT}
    
    log_info "Starting Mock PVE API Server on port $port..."
    
    # Stop any existing containers first
    stop_existing_containers
    
    # Remove any existing containers with the same name
    podman rm mock-pve-api 2>/dev/null || true
    
    # Run the container
    podman run -d \
        --name mock-pve-api \
        --userns=keep-id \
        -p "${port}:8006" \
        -e MOCK_PVE_VERSION=8.3 \
        -e MOCK_PVE_LOG_LEVEL=info \
        "$MOCK_PVE_IMAGE"
    
    log_success "Mock PVE API Server started"
    log_info "Access the API at: http://localhost:${port}"
}

# Wait for Mock PVE API to be ready
wait_for_api() {
    local port=${1:-$DEFAULT_PORT}
    local max_attempts=30
    local attempt=1
    
    log_info "Waiting for Mock PVE API to be ready..."
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -sf "http://localhost:${port}/api2/json/version" >/dev/null 2>&1; then
            log_success "Mock PVE API is ready!"
            return 0
        fi
        
        if [[ $((attempt % 5)) -eq 0 ]] && [[ "${SETUP_MODE}" != "quiet" ]]; then
            log_info "Still waiting... (attempt $attempt/$max_attempts)"
        fi
        
        sleep 2
        ((attempt++))
    done
    
    log_error "Mock PVE API failed to start within expected time"
    return 1
}

# Verify Mock PVE API functionality
verify_mock_pve_api() {
    local port=${1:-$DEFAULT_PORT}
    
    log_info "Verifying Mock PVE API functionality..."
    
    # Test version endpoint
    local version_response
    if ! version_response=$(curl -sf "http://localhost:${port}/api2/json/version" 2>/dev/null); then
        log_error "Failed to connect to Mock PVE API"
        return 1
    fi
    
    # Parse version from response
    local version
    if command -v jq >/dev/null 2>&1; then
        version=$(echo "$version_response" | jq -r '.data.version // "unknown"')
    else
        version="detected"
    fi
    
    log_success "Mock PVE API is running (PVE version: $version)"
    
    # Test additional endpoints
    local endpoints=("nodes" "cluster/status")
    for endpoint in "${endpoints[@]}"; do
        if curl -sf "http://localhost:${port}/api2/json/${endpoint}" >/dev/null 2>&1; then
            log_success "✓ /${endpoint} endpoint working"
        else
            log_warning "⚠ /${endpoint} endpoint not responding"
        fi
    done
}

# Cleanup function
cleanup_containers() {
    log_info "Cleaning up Mock PVE API containers..."
    
    # Stop and remove all containers with mock-pve in the name
    local containers
    containers=$(podman ps -aq --filter "name=mock-pve" 2>/dev/null || true)
    
    if [[ -n "$containers" ]]; then
        echo "$containers" | xargs podman stop 2>/dev/null || true
        echo "$containers" | xargs podman rm 2>/dev/null || true
        log_success "Cleaned up Mock PVE containers"
    else
        log_info "No Mock PVE containers found"
    fi
    
    # Remove unused images (optional)
    if [[ "${SETUP_MODE}" != "quiet" ]]; then
        echo
        read -p "Remove Mock PVE API images as well? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            podman rmi "$MOCK_PVE_IMAGE" 2>/dev/null || true
            log_success "Removed Mock PVE API images"
        fi
    fi
}

# Show usage examples
show_examples() {
    cat << EOF

${GREEN}Mock PVE API Server is now running!${NC}

${BLUE}Quick Test Commands:${NC}
  # Check version
  curl http://localhost:${DEFAULT_PORT}/api2/json/version

  # List nodes  
  curl http://localhost:${DEFAULT_PORT}/api2/json/nodes

  # Check cluster status
  curl http://localhost:${DEFAULT_PORT}/api2/json/cluster/status

${BLUE}Container Management:${NC}
  # View logs
  podman logs mock-pve-api

  # Stop container
  podman stop mock-pve-api

  # Start again
  podman start mock-pve-api

  # Remove container
  podman rm mock-pve-api

${BLUE}Run Different PVE Versions:${NC}
  # PVE 7.4
  podman run -d --name mock-pve-74 -p 8007:8006 \\
    -e MOCK_PVE_VERSION=7.4 ${MOCK_PVE_IMAGE}

  # PVE 8.0 
  podman run -d --name mock-pve-80 -p 8008:8006 \\
    -e MOCK_PVE_VERSION=8.0 ${MOCK_PVE_IMAGE}

${BLUE}Documentation:${NC}
  https://github.com/jrjsmrtn/mock-pve-api

EOF
}

# Main setup function
main_setup() {
    local port=$DEFAULT_PORT
    local install_only=false
    local run_only=false
    
    # Process arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--version)
                echo "Mock PVE API Setup Script v${SCRIPT_VERSION}"
                exit 0
                ;;
            -q|--quiet)
                SETUP_MODE="quiet"
                shift
                ;;
            -y|--yes)
                SETUP_MODE="auto"
                shift
                ;;
            -p|--port)
                port="$2"
                shift 2
                ;;
            --install-only)
                install_only=true
                shift
                ;;
            --run-only)
                run_only=true
                shift
                ;;
            --cleanup)
                cleanup_containers
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Banner
    if [[ "${SETUP_MODE}" != "quiet" ]]; then
        echo -e "${BLUE}"
        echo "╔═══════════════════════════════════════╗"
        echo "║        Mock PVE API - Podman Setup    ║"
        echo "║                                       ║"
        echo "║  This script will install Podman     ║"
        echo "║  and setup Mock PVE API Server       ║"
        echo "╚═══════════════════════════════════════╝"
        echo -e "${NC}"
    fi
    
    # Install Podman (unless run-only mode)
    if [[ "$run_only" != true ]]; then
        if ! check_podman; then
            if [[ "${SETUP_MODE}" == "interactive" ]]; then
                echo
                read -p "Install Podman now? [Y/n]: " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Nn]$ ]]; then
                    log_error "Podman is required. Exiting."
                    exit 1
                fi
            fi
            
            install_podman
            configure_podman
            verify_podman
        fi
    fi
    
    # Exit if install-only mode
    if [[ "$install_only" == true ]]; then
        log_success "Podman installation complete"
        exit 0
    fi
    
    # Setup Mock PVE API
    if [[ "${SETUP_MODE}" == "interactive" ]]; then
        echo
        read -p "Setup Mock PVE API Server on port $port? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log_info "Setup cancelled by user"
            exit 0
        fi
    fi
    
    # Check for port conflicts
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "Port $port is already in use"
        if [[ "${SETUP_MODE}" == "interactive" ]]; then
            read -p "Continue anyway? [y/N]: " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_error "Setup cancelled due to port conflict"
                exit 1
            fi
        fi
    fi
    
    # Run Mock PVE API
    pull_mock_pve_image
    run_mock_pve_api "$port"
    
    # Wait and verify
    if wait_for_api "$port"; then
        verify_mock_pve_api "$port"
        
        if [[ "${SETUP_MODE}" != "quiet" ]]; then
            show_examples
        fi
    else
        log_error "Setup failed - Mock PVE API is not responding"
        log_info "Check logs with: podman logs mock-pve-api"
        exit 1
    fi
    
    log_success "Setup complete! Mock PVE API Server is running on port $port"
}

# Error handling
trap 'log_error "Setup interrupted"; exit 1' INT TERM

# Dependency checks
check_dependencies() {
    local missing_deps=()
    
    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    # Check for lsof (for port checking)
    if ! command -v lsof >/dev/null 2>&1; then
        log_warning "lsof not found - port conflict detection disabled"
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install them and run this script again"
        exit 1
    fi
}

# Run dependency check and main setup
check_dependencies
main_setup "$@"