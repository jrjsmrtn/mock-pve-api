# SBOM and Security Documentation

This document provides comprehensive information about Software Bill of Materials (SBOM) generation and security practices for the Mock PVE API project.

## Overview

The Mock PVE API project implements comprehensive SBOM generation and security scanning to ensure supply chain transparency and security compliance. This supports organizations in meeting security requirements and regulatory compliance.

## What is an SBOM?

A Software Bill of Materials (SBOM) is a formal record containing the details and supply chain relationships of components used in building software. It provides transparency into the software supply chain and enables:

- **Security Analysis**: Identify vulnerabilities in dependencies
- **License Compliance**: Track software licenses and obligations
- **Risk Assessment**: Understand supply chain risks
- **Regulatory Compliance**: Meet government and industry requirements

## SBOM Generation

### Automatic Generation

SBOM files are automatically generated in the CI/CD pipeline:

- **On every push**: Source code SBOM generation
- **On container builds**: Container image SBOM generation
- **On releases**: SBOM files attached to GitHub releases

### Manual Generation

Generate SBOM files locally using the provided script:

```bash
# Generate all SBOM formats
make sbom

# Or use the script directly
./scripts/generate-sbom.sh

# Generate specific types
make sbom-deps      # Dependencies only
make sbom-source    # Source code only
make sbom-container # Container image only
```

### Generated Files

The SBOM generation creates multiple files in the `sbom/` directory:

#### Dependencies
- `mix-dependencies.json` - Custom CycloneDX format for Elixir/Mix dependencies
- `source-spdx.json` - SPDX format for source code analysis
- `source-cyclonedx.json` - CycloneDX format for source code analysis
- `source-packages.txt` - Human-readable package list

#### Container Images
- `container-spdx.json` - SPDX format for container image
- `container-cyclonedx.json` - CycloneDX format for container image
- `container-packages.txt` - Human-readable container package list

#### Security Analysis
- `vulnerabilities.json` - Detailed vulnerability report (JSON)
- `vulnerabilities.txt` - Human-readable vulnerability report
- `metadata.json` - SBOM generation metadata

## SBOM Formats

### SPDX (Software Package Data Exchange)

**Format**: JSON  
**Use Case**: License compliance, legal analysis, industry standard  
**Standard**: ISO/IEC 5962:2021

```bash
# View SPDX SBOM
jq '.packages[] | {name: .name, version: .versionInfo, license: .licenseConcluded}' sbom/source-spdx.json
```

### CycloneDX

**Format**: JSON  
**Use Case**: Security analysis, vulnerability management  
**Standard**: OWASP CycloneDX

```bash
# View CycloneDX SBOM
jq '.components[] | {name: .name, version: .version, type: .type}' sbom/source-cyclonedx.json
```

### Custom Mix Format

**Format**: JSON  
**Use Case**: Elixir-specific dependency analysis  
**Features**: Hex package URLs, Mix-specific metadata

```bash
# View Mix dependencies
jq '.components[] | {name: .name, version: .version, purl: .purl}' sbom/mix-dependencies.json
```

## Vulnerability Scanning

### Automatic Scanning

Vulnerability scanning is performed automatically:

- **CI/CD Pipeline**: Every build scans for vulnerabilities
- **Schedule**: (Planned) Weekly automated scans
- **Tools**: Grype for vulnerability detection

### Manual Scanning

Run vulnerability scans locally:

```bash
# Complete security audit
make security-audit

# Vulnerability scan only
make vulnerability-scan

# Direct Grype usage
grype sbom:sbom/source-spdx.json
grype pkg:hex/plug@1.14.2  # Specific package
```

### Vulnerability Report Format

```json
{
  "matches": [
    {
      "vulnerability": {
        "id": "CVE-2023-12345",
        "severity": "High",
        "description": "...",
        "cvss": [...]
      },
      "artifact": {
        "name": "package-name",
        "version": "1.0.0",
        "type": "hex"
      }
    }
  ]
}
```

## Integration with Security Tools

### Dependency Track

Import CycloneDX files for continuous dependency monitoring:

```bash
# Upload to Dependency Track API
curl -X POST "https://dependency-track.example.com/api/v1/bom" \
  -H "X-API-Key: your-api-key" \
  -H "Content-Type: application/json" \
  -d @sbom/source-cyclonedx.json
```

### FOSSA

Import SPDX files for license compliance analysis:

```bash
# FOSSA CLI integration
fossa analyze --data @sbom/source-spdx.json
```

### Snyk

Use SBOM files with Snyk for vulnerability monitoring:

```bash
# Snyk CLI with SBOM
snyk test --file=sbom/source-spdx.json --package-manager=hex
```

### GitHub Security

SBOM files are automatically uploaded to GitHub releases and can be consumed by:

- GitHub Dependency Graph
- Dependabot security alerts
- GitHub Advanced Security

## Compliance and Standards

### Executive Order 14028

This implementation supports compliance with the US Executive Order on "Improving the Nation's Cybersecurity":

- ✅ **SBOM Generation**: Automated SBOM creation for all software artifacts
- ✅ **Vulnerability Scanning**: Regular vulnerability assessment
- ✅ **Supply Chain Visibility**: Complete dependency transparency
- ✅ **Industry Standards**: SPDX and CycloneDX format support

### NIST Cybersecurity Framework

Alignment with NIST CSF functions:

- **Identify**: SBOM provides complete asset inventory
- **Protect**: Vulnerability scanning enables risk mitigation
- **Detect**: Continuous monitoring of security threats
- **Respond**: Rapid vulnerability identification and patching
- **Recover**: Component-level incident response capability

### Container Security

For containerized deployments:

- **Base Image Transparency**: Complete OS package visibility
- **Layer Analysis**: Per-layer dependency tracking
- **Runtime Security**: SBOM integration with container security tools
- **Registry Integration**: SBOM metadata in container registries

## Configuration

### Environment Variables

SBOM generation can be configured via environment variables:

```bash
# Skip vulnerability scanning (faster builds)
export SBOM_SKIP_VULNS=true

# Custom SBOM output directory
export SBOM_OUTPUT_DIR=/custom/path

# Additional Syft configuration
export SYFT_CONFIG_FILE=/path/to/syft.yaml
```

### CI/CD Configuration

GitHub Actions configuration in `.github/workflows/ci.yml`:

```yaml
- name: Generate SBOM files
  run: ./scripts/generate-sbom.sh --source

- name: Upload SBOM artifacts
  uses: actions/upload-artifact@v3
  with:
    name: sbom-files
    path: sbom/
```

## Best Practices

### Development

1. **Regular Updates**: Keep dependencies updated to minimize vulnerabilities
2. **SBOM Review**: Review SBOM changes in pull requests
3. **Vulnerability Monitoring**: Address high-severity vulnerabilities promptly
4. **License Compliance**: Ensure compatible license usage

### Production

1. **SBOM Archival**: Store SBOM files for deployed versions
2. **Incident Response**: Use SBOM for security incident investigation
3. **Compliance Reporting**: Leverage SBOM for audit and compliance
4. **Supply Chain Risk**: Monitor for supply chain attacks

### Security

1. **Access Control**: Limit access to detailed SBOM files
2. **Sensitive Information**: Review SBOM files before public sharing
3. **Automation**: Integrate SBOM generation into CI/CD pipelines
4. **Monitoring**: Set up alerts for new vulnerabilities

## Troubleshooting

### Common Issues

**SBOM Generation Fails**
```bash
# Check script permissions
chmod +x scripts/generate-sbom.sh

# Install required tools
./scripts/generate-sbom.sh  # Auto-installs tools
```

**Missing Dependencies**
```bash
# Install Syft
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Install Grype
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```

**Container Image Not Found**
```bash
# Build container image first
make container-build

# Then generate container SBOM
make sbom-container
```

### Debug Mode

Enable debug output for troubleshooting:

```bash
# Debug SBOM generation
SYFT_LOG_LEVEL=debug ./scripts/generate-sbom.sh

# Debug vulnerability scanning
GRYPE_LOG_LEVEL=debug make vulnerability-scan
```

## Resources

### Standards and Specifications

- [SPDX Specification](https://spdx.github.io/spdx-spec/)
- [CycloneDX Standard](https://cyclonedx.org/)
- [NIST SSDF](https://csrc.nist.gov/Projects/ssdf)
- [Executive Order 14028](https://www.whitehouse.gov/briefing-room/presidential-actions/2021/05/12/executive-order-on-improving-the-nations-cybersecurity/)

### Tools and Documentation

- [Syft Documentation](https://github.com/anchore/syft)
- [Grype Documentation](https://github.com/anchore/grype)
- [Dependency Track](https://dependencytrack.org/)
- [FOSSA](https://fossa.com/)

### Community

- [SPDX Community](https://spdx.dev/)
- [OWASP CycloneDX](https://owasp.org/www-project-cyclonedx/)
- [CISA SBOM Resources](https://www.cisa.gov/sbom)

---

For questions about SBOM implementation or security practices, please refer to the project documentation or open an issue in the GitHub repository.