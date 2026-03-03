# Sprint 4.9.12 — Node Stubs, TFA Per-Entry, SDN Vnet Firewall

**Date**: 2026-03-03
**Version**: v0.4.18
**Branch**: develop

## Summary

Closed 36 coverage gaps across four categories:

1. **Node APT/capabilities/certificates/disks/console stubs** — 22 new catalog entries, new routes + handler functions
2. **VM/LXC specific status action entries** — 13 catalog entries (routes already handled by catch-all)
3. **Access TFA per-entry + user TFA methods/unlock** — 4 new catalog entries, new routes + handlers
4. **SDN vnet firewall stubs** — 5 new catalog entries, 8 new routes + handlers

## Statistics

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Version | 0.4.17 | 0.4.18 | +0.0.1 |
| Tests | 966 | 1007 | +41 |
| Coverage catalog | 532 | 568 | +36 |
| Missing from EndpointMatrix | 142 | 106 | -36 |
| Method mismatches | 0 | 0 | 0 |

## Changes

### New Handler Functions

**`handlers/nodes.ex`**:
- `post_apt_repositories/1` — POST /nodes/:node/apt/repositories
- `get_qemu_cpu_flags/1` — GET /nodes/:node/capabilities/qemu/cpu-flags (9.0+)
- `get_qemu_migration_capabilities/1` — GET /nodes/:node/capabilities/qemu/migration (9.0+)

(Other node handlers were added in the previous session: `get_apt_index`, `get_apt_changelog`,
`get_apt_repositories`, `update_apt_repositories`, `get_capabilities_index`, `get_qemu_capabilities`,
`get_qemu_cpu_capabilities`, `get_qemu_machine_capabilities`, `get_certificates_index`,
`get_acme_cert_index`, `manage_custom_certificate`, `get_disks_directory`, `create_disks_directory`,
`delete_disks_directory`, `node_console_stub`, `get_node_vncwebsocket`, `node_wakeonlan`,
`node_suspendall`)

**`handlers/access.ex`**:
- `get_tfa_entry/1`, `update_tfa_entry/1`, `delete_tfa_entry/1` — TFA per-entry CRUD
- `get_user_tfa_methods/1` — GET /access/users/:userid/tfa
- `unlock_user_tfa/1` — PUT /access/users/:userid/unlock-tfa

**`handlers/firewall.ex`**:
- `get_sdn_vnet_firewall_index/1`
- `get_sdn_vnet_firewall_options/1`, `update_sdn_vnet_firewall_options/1`
- `list_sdn_vnet_firewall_rules/1`, `create_sdn_vnet_firewall_rule/1`
- `get_sdn_vnet_firewall_rule/1`, `update_sdn_vnet_firewall_rule/1`, `delete_sdn_vnet_firewall_rule/1`

### New Routes (`router.ex`)

**Access**:
- `GET /api2/json/access/users/:userid/tfa`
- `PUT /api2/json/access/users/:userid/unlock-tfa`
- `GET/PUT/DELETE /api2/json/access/tfa/:userid/:id`

**Node apt** (before existing apt/update and apt/versions):
- `GET /api2/json/nodes/:node/apt`
- `GET /api2/json/nodes/:node/apt/changelog`
- `GET/POST/PUT /api2/json/nodes/:node/apt/repositories`

**Node capabilities** (new section):
- `GET /api2/json/nodes/:node/capabilities`
- `GET /api2/json/nodes/:node/capabilities/qemu`
- `GET /api2/json/nodes/:node/capabilities/qemu/cpu`
- `GET /api2/json/nodes/:node/capabilities/qemu/cpu-flags`
- `GET /api2/json/nodes/:node/capabilities/qemu/machines`
- `GET /api2/json/nodes/:node/capabilities/qemu/migration`

**Node certificates** (before existing ACME cert routes):
- `GET /api2/json/nodes/:node/certificates`
- `GET /api2/json/nodes/:node/certificates/acme`
- `POST/DELETE /api2/json/nodes/:node/certificates/custom`

**Node disks** (after existing disks/initgpt):
- `GET/POST /api2/json/nodes/:node/disks/directory`
- `DELETE /api2/json/nodes/:node/disks/directory/:name`

**Node console/power** (after services section):
- `POST /api2/json/nodes/:node/termproxy`
- `POST /api2/json/nodes/:node/spiceshell`
- `GET /api2/json/nodes/:node/vncwebsocket`
- `POST /api2/json/nodes/:node/wakeonlan`
- `POST /api2/json/nodes/:node/suspendall`

**SDN vnet firewall** (before generic vnet GET/PUT/DELETE):
- `GET /api2/json/cluster/sdn/vnets/:vnet/firewall`
- `GET/PUT /api2/json/cluster/sdn/vnets/:vnet/firewall/options`
- `GET/POST /api2/json/cluster/sdn/vnets/:vnet/firewall/rules`
- `GET/PUT/DELETE /api2/json/cluster/sdn/vnets/:vnet/firewall/rules/:pos`

### New Coverage Entries

**`coverage/nodes.ex`** (+22 entries):
- apt (index, changelog, repositories)
- capabilities (index, qemu, qemu/cpu, qemu/cpu-flags, qemu/machines, qemu/migration)
- certificates (index, acme, custom)
- disks/directory (list+create, delete by name)
- termproxy, vncwebsocket, spiceshell, wakeonlan, suspendall

**`coverage/vms.ex`** (+7 entries, Sprint 4.9.12):
- VM status actions: start, stop, reset, reboot, shutdown, resume, suspend

**`coverage/containers.ex`** (+6 entries, Sprint 4.9.12):
- LXC status actions: start, stop, reboot, shutdown, resume, suspend

**`coverage/access.ex`** (+4 entries):
- `/access/tfa/{userid}/{id}` (GET/PUT/DELETE)
- `/access/users/{userid}/tfa` (GET)
- `/access/users/{userid}/unlock-tfa` (PUT)

**`coverage/sdn.ex`** (+5 entries):
- SDN vnet firewall: index, options, rules, rules/{pos}

### New Helper Methods in `coverage/nodes.ex`
- `methods_for(:get_post_put)` → `[:get, :post, :put]`
- `methods_for(:post_delete)` → `[:post, :delete]`

### `coverage_test.exs` Updates
- Added 13 VM/LXC status action paths to `action_endpoints` whitelist
- Added 4 node console/power paths to `action_endpoints`
- Added `certificates/custom` to `action_endpoints`
- Added `unlock-tfa` to `put_only_actions`
- Updated `get_endpoint_info` test: `/status/start` now correctly returns specific entry

## New Test File

`test/mock_pve_api/handlers/sprint_12_test.exs` — 41 tests covering all new endpoints.

## Notes

- SDN vnet firewall handlers are lightweight stubs (no state); the endpoint routes and catalog
  entries satisfy EndpointMatrix diff requirements.
- VM/LXC status action entries added to coverage catalog; actual routing is handled by existing
  parameterized catch-all routes (`status/:command`). The catalog entries satisfy coverage_diff
  which compares exact path strings against the EndpointMatrix.
- The `coverage_test.exs` test for `get_endpoint_info` was updated: adding specific
  `/status/start` entries means the coverage system now returns the most specific match (the
  concrete path) rather than the parameterized `/status/{command}` path. This is correct behavior.
