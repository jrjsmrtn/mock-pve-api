# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.4.x   | Yes       |
| < 0.4   | No        |

## Reporting a Vulnerability

If you discover a security vulnerability in mock-pve-api, please report it
responsibly.

**Do not open a public issue.**

Instead, send an email to <jrjsmrtn@gmail.com> with:

- A description of the vulnerability
- Steps to reproduce
- Affected version(s)
- Any suggested fix (optional)

### Response timeline

This project is maintained by a single person. Please allow reasonable time
for a response:

- **Acknowledgement**: within 7 days
- **Assessment and initial response**: within 14 days
- **Fix for confirmed vulnerabilities**: best effort, typically within 30 days

If you have not received a response within 14 days, feel free to follow up on
the same thread.

### Scope

mock-pve-api is a **testing and development tool** that simulates the Proxmox
VE API. It is not designed to run in production or handle real credentials.
That said, vulnerabilities in container images, dependency supply chain, or
secret leakage are taken seriously.

### Disclosure

Once a fix is released, the vulnerability will be documented in the
CHANGELOG.md and, where appropriate, a GitHub Security Advisory will be
created.
