#!/bin/bash
# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT
set -euo pipefail

# SBOM Generation Script for Mock PVE API
# Generates Software Bill of Materials for supply chain security compliance
#
# Supports multiple SBOM formats:
# - SPDX (Software Package Data Exchange)
# - CycloneDX (for vulnerability scanning)
# - JSON and XML formats
# - Container image SBOM generation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SBOM_DIR="${PROJECT_DIR}/sbom"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are available
check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing_tools=()
    
    # Check for syft (for SBOM generation)
    if ! command -v syft &> /dev/null; then
        missing_tools+=("syft")
    fi
    
    # Check for grype (for vulnerability scanning)
    if ! command -v grype &> /dev/null; then
        missing_tools+=("grype")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_warning "Missing tools: ${missing_tools[*]}"
        log_info "Installing missing tools..."
        install_tools "${missing_tools[@]}"
    else
        log_success "All required tools are available"
    fi
}

# Install required SBOM tools
install_tools() {
    local tools=("$@")
    
    for tool in "${tools[@]}"; do
        case $tool in
            "syft")
                log_info "Installing Syft..."
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS - use curl to install
                    curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
                else
                    # Linux - use curl to install
                    curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
                fi
                ;;
            "grype")
                log_info "Installing Grype..."
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS - use curl to install  
                    curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
                else
                    # Linux - use curl to install
                    curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
                fi
                ;;
        esac
    done
}

# Create SBOM directory
setup_directories() {
    log_info "Setting up SBOM directories..."
    mkdir -p "$SBOM_DIR"
    log_success "SBOM directory created: $SBOM_DIR"
}

# Generate Elixir/Mix dependency SBOM
generate_mix_sbom() {
    log_info "Generating Mix dependency SBOM..."
    
    cd "$PROJECT_DIR"
    
    # Generate mix dependency list
    mix deps.get --only prod &> /dev/null || true
    
    # Create custom Mix SBOM in JSON format
    cat > "$SBOM_DIR/mix-dependencies.json" << EOF
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "serialNumber": "urn:uuid:$(uuidgen | tr '[:upper:]' '[:lower:]')",
  "version": 1,
  "metadata": {
    "timestamp": "$TIMESTAMP",
    "tools": [
      {
        "vendor": "mock-pve-api",
        "name": "generate-sbom.sh",
        "version": "1.0.0"
      }
    ],
    "component": {
      "type": "application",
      "bom-ref": "mock-pve-api",
      "name": "mock-pve-api",
      "version": "$(grep 'version:' mix.exs | sed 's/.*version: "\([^"]*\)".*/\1/')",
      "description": "Mock Proxmox VE API Server for testing and development",
      "licenses": [
        {
          "license": {
            "id": "MIT"
          }
        }
      ]
    }
  },
  "components": [
EOF

    # Parse mix.lock and add dependencies
    local first_dep=true
    while IFS= read -r line; do
        if [[ $line =~ \"([^\"]+)\":[[:space:]]*\{:hex,[[:space:]]*:([^,]+),[[:space:]]*\"([^\"]+)\" ]]; then
            local dep_name="${BASH_REMATCH[1]}"
            local dep_version="${BASH_REMATCH[3]}"
            
            if [ "$first_dep" = false ]; then
                echo "    ," >> "$SBOM_DIR/mix-dependencies.json"
            fi
            first_dep=false
            
            cat >> "$SBOM_DIR/mix-dependencies.json" << EOF
    {
      "type": "library",
      "bom-ref": "pkg:hex/${dep_name}@${dep_version}",
      "name": "${dep_name}",
      "version": "${dep_version}",
      "purl": "pkg:hex/${dep_name}@${dep_version}",
      "scope": "required"
    }
EOF
        fi
    done < mix.lock
    
    cat >> "$SBOM_DIR/mix-dependencies.json" << EOF

  ]
}
EOF
    
    log_success "Mix SBOM generated: $SBOM_DIR/mix-dependencies.json"
}

# Generate container image SBOM using Syft
generate_container_sbom() {
    log_info "Generating container image SBOM..."
    
    local image_name="mock-pve-api:latest"
    local image_exists=false
    
    # Check if container image exists
    if podman images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image_name}$"; then
        image_exists=true
        log_info "Using Podman image: $image_name"
    elif docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "^${image_name}$"; then
        image_exists=true
        log_info "Using Docker image: $image_name"
    fi
    
    if [ "$image_exists" = true ]; then
        # Generate SPDX format
        syft "$image_name" -o spdx-json > "$SBOM_DIR/container-spdx.json" 2>/dev/null || {
            log_warning "Failed to generate SPDX SBOM for container image"
        }
        
        # Generate CycloneDX format
        syft "$image_name" -o cyclonedx-json > "$SBOM_DIR/container-cyclonedx.json" 2>/dev/null || {
            log_warning "Failed to generate CycloneDX SBOM for container image"
        }
        
        # Generate table format for human reading
        syft "$image_name" -o table > "$SBOM_DIR/container-packages.txt" 2>/dev/null || {
            log_warning "Failed to generate table SBOM for container image"
        }
        
        log_success "Container SBOM generated for image: $image_name"
    else
        log_warning "Container image $image_name not found. Build the image first with 'make container-build'"
    fi
}

# Generate source code SBOM using Syft
generate_source_sbom() {
    log_info "Generating source code SBOM..."
    
    cd "$PROJECT_DIR"
    
    # Generate SPDX format for source directory
    syft dir:. -o spdx-json > "$SBOM_DIR/source-spdx.json" 2>/dev/null || {
        log_warning "Failed to generate SPDX SBOM for source code"
    }
    
    # Generate CycloneDX format for source directory
    syft dir:. -o cyclonedx-json > "$SBOM_DIR/source-cyclonedx.json" 2>/dev/null || {
        log_warning "Failed to generate CycloneDX SBOM for source code"
    }
    
    # Generate table format for human reading
    syft dir:. -o table > "$SBOM_DIR/source-packages.txt" 2>/dev/null || {
        log_warning "Failed to generate table SBOM for source code"
    }
    
    log_success "Source code SBOM generated"
}

# Generate vulnerability report using Grype
generate_vulnerability_report() {
    log_info "Generating vulnerability report..."
    
    local sbom_file="$SBOM_DIR/source-spdx.json"
    
    if [ -f "$sbom_file" ]; then
        # Generate vulnerability report in JSON format
        grype "sbom:$sbom_file" -o json > "$SBOM_DIR/vulnerabilities.json" 2>/dev/null || {
            log_warning "Failed to generate vulnerability report"
            return
        }
        
        # Generate human-readable vulnerability report
        grype "sbom:$sbom_file" -o table > "$SBOM_DIR/vulnerabilities.txt" 2>/dev/null || {
            log_warning "Failed to generate human-readable vulnerability report"
        }
        
        log_success "Vulnerability report generated"
    else
        log_warning "SBOM file not found for vulnerability scanning"
    fi
}

# Generate SBOM metadata file
generate_metadata() {
    log_info "Generating SBOM metadata..."
    
    local version
    version=$(grep 'version:' "$PROJECT_DIR/mix.exs" | sed 's/.*version: "\([^"]*\)".*/\1/')
    
    cat > "$SBOM_DIR/metadata.json" << EOF
{
  "project": {
    "name": "mock-pve-api",
    "version": "$version",
    "description": "Mock Proxmox VE API Server for testing and development",
    "license": "MIT",
    "repository": "https://github.com/jrjsmrtn/mock-pve-api",
    "registry": "docker.io/jrjsmrtn/mock-pve-api"
  },
  "sbom": {
    "generated_at": "$TIMESTAMP",
    "generator": "mock-pve-api/generate-sbom.sh",
    "formats": [
      "SPDX-JSON",
      "CycloneDX-JSON",
      "Custom-Mix-JSON"
    ],
    "files": [
      "mix-dependencies.json",
      "source-spdx.json",
      "source-cyclonedx.json",
      "source-packages.txt",
      "container-spdx.json",
      "container-cyclonedx.json",
      "container-packages.txt",
      "vulnerabilities.json",
      "vulnerabilities.txt"
    ]
  },
  "security": {
    "vulnerability_scanning": true,
    "last_scanned": "$TIMESTAMP",
    "scanner": "grype"
  }
}
EOF
    
    log_success "SBOM metadata generated: $SBOM_DIR/metadata.json"
}

# Generate README for SBOM directory
generate_sbom_readme() {
    log_info "Generating SBOM README..."
    
    cat > "$SBOM_DIR/README.md" << 'EOF'
# Software Bill of Materials (SBOM)

This directory contains Software Bill of Materials (SBOM) files for the Mock PVE API project, providing transparency into the software supply chain and enabling security analysis.

## Files Overview

### Dependencies
- `mix-dependencies.json` - Custom CycloneDX format SBOM for Elixir/Mix dependencies
- `source-spdx.json` - SPDX format SBOM for source code analysis
- `source-cyclonedx.json` - CycloneDX format SBOM for source code analysis
- `source-packages.txt` - Human-readable package list for source code

### Container Images
- `container-spdx.json` - SPDX format SBOM for container image
- `container-cyclonedx.json` - CycloneDX format SBOM for container image  
- `container-packages.txt` - Human-readable package list for container image

### Security Analysis
- `vulnerabilities.json` - Detailed vulnerability report in JSON format
- `vulnerabilities.txt` - Human-readable vulnerability report
- `metadata.json` - SBOM generation metadata and project information

## SBOM Formats

### SPDX (Software Package Data Exchange)
- Industry standard for software bill of materials
- Used for license compliance and security analysis
- Format: `*.spdx.json`

### CycloneDX
- OWASP standard for application security testing
- Optimized for vulnerability management and security analysis
- Format: `*.cyclonedx.json`

### Custom Mix Format
- Tailored for Elixir/Mix dependency analysis
- Includes Hex package URLs and version information
- Format: `mix-dependencies.json`

## Usage

### Viewing SBOM Contents
```bash
# View Mix dependencies
jq '.components[] | {name: .name, version: .version}' mix-dependencies.json

# View container packages
jq '.artifacts[] | {name: .name, version: .version, type: .type}' container-spdx.json

# View vulnerabilities
jq '.matches[] | {vulnerability: .vulnerability.id, severity: .vulnerability.severity, package: .artifact.name}' vulnerabilities.json
```

### Security Analysis
```bash
# Scan for new vulnerabilities
grype sbom:source-spdx.json

# Check specific package
grype pkg:hex/plug@1.14.2
```

### Integration with Security Tools
- **Dependency Track**: Import CycloneDX files for continuous dependency monitoring
- **FOSSA**: Import SPDX files for license compliance analysis
- **Snyk**: Use SBOM files for vulnerability scanning and monitoring
- **GitHub Dependency Graph**: Upload SPDX files for security alerts

## Regeneration

To regenerate SBOM files:
```bash
./scripts/generate-sbom.sh
```

## Compliance

These SBOM files support compliance with:
- **Executive Order 14028** (Improving the Nation's Cybersecurity)
- **NIST Cybersecurity Framework**
- **Supply Chain Security requirements**
- **Container security best practices**

## Security Considerations

- SBOM files may contain sensitive information about dependencies
- Review files before sharing in public repositories
- Regularly update SBOM files when dependencies change
- Monitor vulnerability reports for security updates

Generated by: mock-pve-api/generate-sbom.sh
EOF

    log_success "SBOM README generated: $SBOM_DIR/README.md"
}

# Create .gitignore for SBOM directory  
create_sbom_gitignore() {
    cat > "$SBOM_DIR/.gitignore" << 'EOF'
# Ignore vulnerability reports (may contain sensitive info)
vulnerabilities.json
vulnerabilities.txt

# Keep SBOM files but ignore temporary files
*.tmp
*.temp
*.bak
EOF
}

# Main execution
main() {
    log_info "Starting SBOM generation for Mock PVE API..."
    
    setup_directories
    check_dependencies
    generate_mix_sbom
    generate_source_sbom
    generate_container_sbom
    generate_vulnerability_report
    generate_metadata
    generate_sbom_readme
    create_sbom_gitignore
    
    log_success "SBOM generation completed!"
    log_info "SBOM files available in: $SBOM_DIR"
    
    # List generated files
    if [ -d "$SBOM_DIR" ]; then
        echo
        log_info "Generated files:"
        find "$SBOM_DIR" -type f -exec basename {} \; | sort | sed 's/^/  - /'
    fi
}

# Handle command line arguments
case "${1:-}" in
    "--help" | "-h")
        echo "SBOM Generation Script for Mock PVE API"
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  -h, --help     Show this help message"
        echo "  --deps-only    Generate only dependency SBOM"
        echo "  --container    Generate only container SBOM"
        echo "  --source       Generate only source code SBOM"
        echo "  --no-vuln      Skip vulnerability scanning"
        echo
        echo "Examples:"
        echo "  $0                 # Generate all SBOM files"
        echo "  $0 --deps-only     # Generate only Mix dependencies SBOM"
        echo "  $0 --container     # Generate only container image SBOM"
        exit 0
        ;;
    "--deps-only")
        setup_directories
        generate_mix_sbom
        generate_metadata
        ;;
    "--container")
        setup_directories
        check_dependencies
        generate_container_sbom
        generate_metadata
        ;;
    "--source")
        setup_directories
        check_dependencies
        generate_source_sbom
        generate_metadata
        ;;
    "--no-vuln")
        setup_directories
        check_dependencies
        generate_mix_sbom
        generate_source_sbom
        generate_container_sbom
        generate_metadata
        generate_sbom_readme
        create_sbom_gitignore
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac