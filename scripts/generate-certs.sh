#!/bin/bash
# Certificate Generation Script for Mock PVE API Server
# Generates self-signed certificates for SSL/TLS testing

set -euo pipefail

# Configuration
CERT_DIR="certs"
KEY_FILE="$CERT_DIR/server.key"
CERT_FILE="$CERT_DIR/server.crt"
CSR_FILE="$CERT_DIR/server.csr"
CONFIG_FILE="$CERT_DIR/openssl.conf"

# Certificate details
COUNTRY="US"
STATE="Test"
LOCALITY="Test"
ORGANIZATION="Mock PVE API"
UNIT="Development"
COMMON_NAME="localhost"
DAYS=365

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if openssl is available
check_openssl() {
    if ! command -v openssl &> /dev/null; then
        log_error "OpenSSL is required but not installed"
        log_info "On macOS: port install openssl"
        log_info "On Ubuntu/Debian: apt-get install openssl"
        log_info "On RHEL/CentOS: yum install openssl"
        exit 1
    fi
}

# Create certificates directory
create_cert_dir() {
    if [[ -d "$CERT_DIR" ]]; then
        log_warn "Certificate directory $CERT_DIR already exists"
        read -p "Do you want to overwrite existing certificates? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Certificate generation cancelled"
            exit 0
        fi
        rm -rf "$CERT_DIR"
    fi
    
    mkdir -p "$CERT_DIR"
    log_info "Created certificate directory: $CERT_DIR"
}

# Generate OpenSSL configuration file
generate_config() {
    log_info "Generating OpenSSL configuration..."
    
    cat > "$CONFIG_FILE" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = $COUNTRY
ST = $STATE
L = $LOCALITY
O = $ORGANIZATION
OU = $UNIT
CN = $COMMON_NAME

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
DNS.3 = 127.0.0.1
DNS.4 = mock-pve-api
DNS.5 = *.mock-pve-api
IP.1 = 127.0.0.1
IP.2 = ::1
EOF
}

# Generate private key
generate_key() {
    log_info "Generating private key..."
    openssl genrsa -out "$KEY_FILE" 2048
    chmod 600 "$KEY_FILE"
    log_info "Private key generated: $KEY_FILE"
}

# Generate certificate signing request
generate_csr() {
    log_info "Generating certificate signing request..."
    openssl req -new -key "$KEY_FILE" -out "$CSR_FILE" -config "$CONFIG_FILE"
    log_info "CSR generated: $CSR_FILE"
}

# Generate self-signed certificate
generate_cert() {
    log_info "Generating self-signed certificate..."
    openssl x509 -req -in "$CSR_FILE" -signkey "$KEY_FILE" -out "$CERT_FILE" \
        -days $DAYS -extensions v3_req -extfile "$CONFIG_FILE"
    chmod 644 "$CERT_FILE"
    log_info "Certificate generated: $CERT_FILE"
}

# Verify certificate
verify_cert() {
    log_info "Verifying certificate..."
    
    # Check certificate details
    log_info "Certificate details:"
    openssl x509 -in "$CERT_FILE" -text -noout | grep -A1 "Subject:"
    openssl x509 -in "$CERT_FILE" -text -noout | grep -A1 "Not Before"
    openssl x509 -in "$CERT_FILE" -text -noout | grep -A1 "Not After"
    
    # Check subject alternative names
    log_info "Subject Alternative Names:"
    openssl x509 -in "$CERT_FILE" -text -noout | grep -A10 "Subject Alternative Name"
    
    # Verify certificate against key
    if openssl x509 -noout -modulus -in "$CERT_FILE" | openssl md5 >/dev/null && \
       openssl rsa -noout -modulus -in "$KEY_FILE" | openssl md5 >/dev/null; then
        log_info "Certificate and key match ✓"
    else
        log_error "Certificate and key do not match ✗"
        exit 1
    fi
}

# Cleanup temporary files
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f "$CSR_FILE" "$CONFIG_FILE"
}

# Show usage instructions
show_usage() {
    log_info "SSL/TLS certificates generated successfully!"
    echo
    log_info "To use these certificates with Mock PVE API:"
    echo "  export MOCK_PVE_SSL_ENABLED=true"
    echo "  export MOCK_PVE_SSL_KEYFILE=$KEY_FILE"
    echo "  export MOCK_PVE_SSL_CERTFILE=$CERT_FILE"
    echo
    log_info "Start the server:"
    echo "  mix run --no-halt"
    echo
    log_info "Test HTTPS connection:"
    echo "  curl -k https://localhost:8006/api2/json/version"
    echo
    log_warn "These are self-signed certificates for testing only!"
    log_warn "Use --insecure (-k) with curl or disable SSL verification in your client."
}

# Main execution
main() {
    log_info "Mock PVE API Certificate Generator"
    log_info "=================================="
    
    check_openssl
    create_cert_dir
    generate_config
    generate_key
    generate_csr
    generate_cert
    verify_cert
    cleanup
    show_usage
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"