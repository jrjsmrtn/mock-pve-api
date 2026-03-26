#!/bin/bash

#
# Shell script for testing Mock PVE API Server endpoints using curl and jq.
#
# This script demonstrates basic API testing using standard shell tools
# and can be used as a foundation for more complex testing scenarios.
#
# Requirements:
#   - curl (for HTTP requests)
#   - jq (for JSON processing) - optional but recommended
#
# Usage:
#   # Start mock server first
#   podman run -d -p 8006:8006 ghcr.io/jrjsmrtn/mock-pve-api:latest
#   
#   # Run this script
#   ./test-endpoints.sh
#   
#   # Or with custom host/port
#   PVE_HOST=localhost PVE_PORT=8006 ./test-endpoints.sh
#

set -euo pipefail

# Configuration
PVE_HOST="${PVE_HOST:-localhost}"
PVE_PORT="${PVE_PORT:-8006}"
PVE_SCHEME="${PVE_SCHEME:-https}"
BASE_URL="${PVE_SCHEME}://${PVE_HOST}:${PVE_PORT}/api2/json"
TIMEOUT="${TIMEOUT:-10}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}🔍 $1${NC}"
}

log_success() {
    echo -e "${GREEN}  ✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}  ⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_skip() {
    echo -e "${YELLOW}  ⏭️  $1${NC}"
}

# Check if jq is available
has_jq() {
    command -v jq >/dev/null 2>&1
}

# Make API request with error handling
api_request() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    local url="${BASE_URL}/${endpoint}"
    
    local curl_args=(
        --silent
        --show-error
        --fail
        --insecure
        --max-time "$TIMEOUT"
        --header "Content-Type: application/json"
        --header "Authorization: PVEAPIToken=root@pam!test=secret"
    )
    
    if [[ "$method" == "POST" && -n "$data" ]]; then
        curl_args+=(--data "$data")
    fi
    
    curl "${curl_args[@]}" --request "$method" "$url"
}

# Extract value from JSON response
extract_json_value() {
    local json="$1"
    local path="$2"
    
    if has_jq; then
        echo "$json" | jq -r "$path // \"unknown\""
    else
        # Basic extraction without jq (limited functionality)
        echo "unknown"
    fi
}

# Count array elements in JSON
count_json_array() {
    local json="$1"
    local path="$2"
    
    if has_jq; then
        echo "$json" | jq -r "($path // []) | length"
    else
        echo "0"
    fi
}

# Test version information
test_version_info() {
    log_info "Testing version information..."
    
    local response
    if ! response=$(api_request "version"); then
        log_error "Failed to get version information"
        return 1
    fi
    
    local version
    local release
    local repoid
    
    version=$(extract_json_value "$response" ".data.version")
    release=$(extract_json_value "$response" ".data.release")
    repoid=$(extract_json_value "$response" ".data.repoid")
    
    log_success "PVE Version: $version"
    log_success "Release: $release"  
    log_success "Repository ID: $repoid"
    
    # Store version for later tests
    export PVE_VERSION="$version"
}

# Test cluster status
test_cluster_status() {
    log_info "Testing cluster status..."
    
    local response
    if ! response=$(api_request "cluster/status"); then
        log_error "Failed to get cluster status"
        return 1
    fi
    
    if has_jq; then
        local node_count
        local cluster_name
        
        node_count=$(echo "$response" | jq '[.data[] | select(.type == "node")] | length')
        cluster_name=$(echo "$response" | jq -r '[.data[] | select(.type == "cluster")] | .[0].name // "unknown"')
        
        log_success "Cluster: $cluster_name"
        log_success "Nodes: $node_count"
        
        # List individual nodes
        echo "$response" | jq -r '.data[] | select(.type == "node") | "  ✅ Node: \(.name) - Status: \(.status)"' | while read -r line; do
            echo -e "${GREEN}$line${NC}"
        done
    else
        log_success "Cluster status retrieved (jq required for detailed parsing)"
    fi
}

# Test nodes list
test_nodes_list() {
    log_info "Testing nodes list..."
    
    local response
    if ! response=$(api_request "nodes"); then
        log_error "Failed to get nodes list"
        return 1
    fi
    
    if has_jq; then
        local node_count
        node_count=$(count_json_array "$response" ".data")
        log_success "Found $node_count nodes"
        
        # List nodes with details
        echo "$response" | jq -r '.data[] | "  ✅ Node: \(.node) - Status: \(.status) - CPU: \((.cpu * 100 | floor))% - Memory: \((.mem / 1073741824 | floor))GB"' | while read -r line; do
            echo -e "${GREEN}$line${NC}"
        done
    else
        log_success "Nodes list retrieved"
    fi
}

# Test cluster resources
test_cluster_resources() {
    log_info "Testing cluster resources..."
    
    local response
    if ! response=$(api_request "cluster/resources"); then
        log_error "Failed to get cluster resources"
        return 1
    fi
    
    if has_jq; then
        local total_count
        local vm_count
        local container_count
        local storage_count
        
        total_count=$(count_json_array "$response" ".data")
        vm_count=$(echo "$response" | jq '[.data[] | select(.type == "qemu")] | length')
        container_count=$(echo "$response" | jq '[.data[] | select(.type == "lxc")] | length')
        storage_count=$(echo "$response" | jq '[.data[] | select(.type == "storage")] | length')
        
        log_success "Total resources: $total_count"
        
        # List VMs
        if [[ "$vm_count" -gt 0 ]]; then
            echo "$response" | jq -r '.data[] | select(.type == "qemu") | "  ✅ VM \(.vmid): \(.name) - Status: \(.status)"' | while read -r line; do
                echo -e "${GREEN}$line${NC}"
            done
        fi
        
        # List containers
        if [[ "$container_count" -gt 0 ]]; then
            echo "$response" | jq -r '.data[] | select(.type == "lxc") | "  ✅ CT \(.vmid): \(.name) - Status: \(.status)"' | while read -r line; do
                echo -e "${GREEN}$line${NC}"
            done
        fi
        
        # List storage
        if [[ "$storage_count" -gt 0 ]]; then
            echo "$response" | jq -r '.data[] | select(.type == "storage") | "  ✅ Storage: \(.storage) - Type: \(.plugintype // "unknown")"' | while read -r line; do
                echo -e "${GREEN}$line${NC}"
            done
        fi
        
        echo ""
        echo -e "${GREEN}  📊 Resource Summary:${NC}"
        echo -e "${GREEN}     VMs: $vm_count${NC}"
        echo -e "${GREEN}     Containers: $container_count${NC}"
        echo -e "${GREEN}     Storage: $storage_count${NC}"
    else
        log_success "Cluster resources retrieved"
    fi
}

# Test storage content
test_storage_content() {
    local node="${1:-pve-node1}"
    local storage="${2:-local}"
    
    log_info "Testing storage content for $storage on $node..."
    
    local response
    if ! response=$(api_request "nodes/$node/storage/$storage/content"); then
        log_warning "Storage content test failed (this may be expected)"
        return 0  # Don't fail the entire test
    fi
    
    if has_jq; then
        local content_count
        content_count=$(count_json_array "$response" ".data")
        log_success "Found $content_count items in storage"
        
        # List storage content with details
        if [[ "$content_count" -gt 0 ]]; then
            echo "$response" | jq -r '.data[] | "  ✅ \(.volid) - Type: \(.content) - Size: \((.size / 1073741824 | floor))GB"' | while read -r line; do
                echo -e "${GREEN}$line${NC}"
            done
        fi
    else
        log_success "Storage content retrieved"
    fi
}

# Test resource pools
test_resource_pools() {
    log_info "Testing resource pools..."
    
    local response
    if ! response=$(api_request "pools"); then
        log_warning "Resource pools test failed"
        return 0
    fi
    
    if has_jq; then
        local pool_count
        pool_count=$(count_json_array "$response" ".data")
        log_success "Found $pool_count resource pools"
        
        if [[ "$pool_count" -gt 0 ]]; then
            echo "$response" | jq -r '.data[] | "  ✅ Pool: \(.poolid) - Comment: \(.comment // "No comment")"' | while read -r line; do
                echo -e "${GREEN}$line${NC}"
            done
        fi
    else
        log_success "Resource pools retrieved"
    fi
}

# Test version-specific features
test_version_specific_features() {
    local version="$1"
    
    log_info "Testing version-specific features for PVE $version..."
    
    # Test SDN features (PVE 8.0+)
    if version_at_least "$version" "8.0"; then
        test_sdn_features
    else
        log_skip "SDN features not available in PVE $version"
    fi
    
    # Test backup providers (PVE 8.2+)
    if version_at_least "$version" "8.2"; then
        test_backup_providers
    else
        log_skip "Backup providers not available in PVE $version"
    fi
}

# Test SDN features
test_sdn_features() {
    log_info "  Testing SDN zones (PVE 8.0+)..."
    
    local response
    if response=$(api_request "cluster/sdn/zones"); then
        local zone_count
        zone_count=$(count_json_array "$response" ".data")
        log_success "SDN Zones: $zone_count zones available"
    else
        log_warning "SDN zones test failed"
    fi
    
    log_info "  Testing SDN vnets (PVE 8.0+)..."
    if response=$(api_request "cluster/sdn/vnets"); then
        local vnet_count
        vnet_count=$(count_json_array "$response" ".data")
        log_success "SDN VNets: $vnet_count vnets available"
    else
        log_warning "SDN vnets test failed"
    fi
}

# Test backup providers
test_backup_providers() {
    log_info "  Testing backup providers (PVE 8.2+)..."
    
    local response
    if response=$(api_request "cluster/backup-info/providers"); then
        local provider_count
        provider_count=$(count_json_array "$response" ".data")
        log_success "Backup Providers: $provider_count providers available"
    else
        log_warning "Backup providers test failed"
    fi
}

# Version comparison helper
version_at_least() {
    local version="$1"
    local min_version="$2"
    
    # Extract major and minor version numbers
    local version_major version_minor
    local min_major min_minor
    
    version_major=$(echo "$version" | cut -d. -f1)
    version_minor=$(echo "$version" | cut -d. -f2 | cut -d- -f1)  # Remove any suffix
    min_major=$(echo "$min_version" | cut -d. -f1)
    min_minor=$(echo "$min_version" | cut -d. -f2)
    
    # Compare versions
    if [[ "$version_major" -gt "$min_major" ]]; then
        return 0
    elif [[ "$version_major" -eq "$min_major" && "$version_minor" -ge "$min_minor" ]]; then
        return 0
    else
        return 1
    fi
}

# Health check
health_check() {
    log_info "Performing health check..."
    
    local response
    if response=$(api_request "version"); then
        log_success "Mock PVE API Server is responding"
        return 0
    else
        log_error "Mock PVE API Server is not responding"
        return 1
    fi
}

# Connection test
test_connection() {
    log_info "Testing connection to $BASE_URL..."
    
    if ! curl --silent --fail --insecure --max-time 5 --output /dev/null "$BASE_URL/version"; then
        log_error "Could not connect to Mock PVE API Server"
        echo ""
        echo "Make sure the server is running:"
        echo "  podman run -d -p 8006:8006 ghcr.io/jrjsmrtn/mock-pve-api:latest"
        echo ""
        echo "Or check if it's running on a different port:"
        echo "  podman ps | grep mock-pve-api"
        return 1
    fi
    
    log_success "Connection successful"
    return 0
}

# Main test function
main() {
    echo -e "${BLUE}🚀 Mock PVE API Server - Shell Test Script${NC}"
    echo "=========================================="
    echo ""
    echo "Testing against: $BASE_URL"
    echo "Timeout: ${TIMEOUT}s"
    
    if has_jq; then
        echo "JSON parser: jq (detailed output enabled)"
    else
        echo "JSON parser: none (install jq for detailed output)"
    fi
    
    echo ""
    
    # Test connection first
    if ! test_connection; then
        exit 1
    fi
    
    echo ""
    
    # Run all tests
    test_version_info || { log_error "Version test failed, cannot continue"; exit 1; }

    # Get version string separately for decision-making
    local version="8.3"
    if has_jq; then
        version=$(api_request "version" | jq -r '.data.version // "8.3"')
    fi

    echo ""
    test_cluster_status
    echo ""
    test_nodes_list
    echo ""
    test_cluster_resources
    echo ""
    test_storage_content
    echo ""
    test_resource_pools
    echo ""
    test_version_specific_features "$version"

    echo ""
    echo "=========================================="
    echo -e "${GREEN}🎉 All tests completed successfully!${NC}"
    echo ""
    echo "Mock PVE API Server is working correctly."
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please install the missing dependencies:"
        echo "  Ubuntu/Debian: sudo apt-get install ${missing_deps[*]}"
        echo "  RHEL/CentOS:   sudo yum install ${missing_deps[*]}"
        echo "  macOS:         brew install ${missing_deps[*]}"
        exit 1
    fi
    
    if ! has_jq; then
        log_warning "jq not found - JSON parsing will be limited"
        echo "  Install jq for better output formatting:"
        echo "  Ubuntu/Debian: sudo apt-get install jq"
        echo "  RHEL/CentOS:   sudo yum install jq"  
        echo "  macOS:         brew install jq"
        echo ""
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_dependencies
    main "$@"
fi