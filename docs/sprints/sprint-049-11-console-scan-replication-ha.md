# Sprint 4.9.11 — Console Stubs, Scan, Replication, HA & Cluster Enhancements

**Version**: v0.4.17
**Date**: 2026-03-03
**Previous**: v0.4.16 (Sprint 4.9.10 — Agent Sub-Commands, Realm-Sync, Mapping)

## Summary

Closed the next highest-ROI coverage gaps across VMs, LXC containers, nodes, and cluster categories. Focused on console/tunnel stubs, node scan/replication/services, and cluster HA/metrics/SDN/bulk-action endpoints.

**Coverage delta**: 430 → 510 catalog entries (+80 endpoints)
**Test delta**: 894 → 966 tests (+72 tests, all passing)
**Method mismatches**: 0

## Changes

### VM Enhancements (`coverage/vms.ex`, `handlers/nodes.ex`, `router.ex`)

New VM endpoints:
- `GET /nodes/{node}/qemu/{vmid}/status` — VM status index
- `GET|PUT /nodes/{node}/qemu/{vmid}/cloudinit` — Cloud-init config get/update
- `POST /nodes/{node}/qemu/{vmid}/vncproxy` — VNC proxy stub
- `POST /nodes/{node}/qemu/{vmid}/termproxy` — Terminal proxy stub
- `POST /nodes/{node}/qemu/{vmid}/spiceproxy` — SPICE proxy stub
- `GET /nodes/{node}/qemu/{vmid}/vncwebsocket` — VNC WebSocket stub
- `POST /nodes/{node}/qemu/{vmid}/mtunnel` — Migration tunnel stub
- `GET /nodes/{node}/qemu/{vmid}/mtunnelwebsocket` — Migration tunnel WebSocket stub
- `POST /nodes/{node}/qemu/{vmid}/remote_migrate` — Remote cluster migration stub
- `POST /nodes/{node}/qemu/{vmid}/monitor` — QEMU monitor command stub

### LXC Container Enhancements (`coverage/containers.ex`, `handlers/nodes.ex`, `router.ex`)

New LXC endpoints:
- `GET /nodes/{node}/lxc/{vmid}/status` — Container status index
- `POST /nodes/{node}/lxc/{vmid}/vncproxy` — VNC proxy stub
- `POST /nodes/{node}/lxc/{vmid}/termproxy` — Terminal proxy stub
- `POST /nodes/{node}/lxc/{vmid}/spiceproxy` — SPICE proxy stub
- `GET /nodes/{node}/lxc/{vmid}/vncwebsocket` — VNC WebSocket stub
- `POST /nodes/{node}/lxc/{vmid}/mtunnel` — Migration tunnel stub
- `GET /nodes/{node}/lxc/{vmid}/mtunnelwebsocket` — Migration tunnel WebSocket stub
- `POST /nodes/{node}/lxc/{vmid}/remote_migrate` — Remote cluster migration stub
- `GET /nodes/{node}/lxc/{vmid}/interfaces` — Network interfaces list

### Node Enhancements (`coverage/nodes.ex`, `handlers/nodes.ex`, `router.ex`)

New node endpoints:
- `GET /nodes/{node}/scan` — Scan types index
- `GET /nodes/{node}/scan/{type}` — Scan for resources (nfs, cifs, lvm, etc.)
- `GET /nodes/{node}/replication` — List node replication jobs
- `GET /nodes/{node}/replication/{id}` — Get replication job on node
- `GET /nodes/{node}/replication/{id}/log` — Replication job log
- `POST /nodes/{node}/replication/{id}/schedule_now` — Schedule replication immediately
- `GET /nodes/{node}/replication/{id}/status` — Detailed replication status
- `POST /nodes/{node}/services/{service}/reload` — Reload service
- `POST /nodes/{node}/services/{service}/restart` — Restart service
- `POST /nodes/{node}/services/{service}/start` — Start service
- `POST /nodes/{node}/services/{service}/stop` — Stop service

### Cluster Enhancements (`coverage/cluster.ex`, `handlers/cluster.ex`, `router.ex`)

New cluster endpoints:
- `GET /cluster/tasks` — List cluster-wide tasks
- `GET /cluster/ha/manager_status` — HA manager status
- `POST /cluster/ha/resources/{sid}/migrate` — Migrate HA resource
- `POST /cluster/ha/resources/{sid}/relocate` — Relocate HA resource
- `GET /cluster/metrics/export` — Export cluster metrics
- `POST|PUT|DELETE /cluster/sdn/vnets/{vnet}/ips` — Vnet IP management
- `GET /cluster/bulk-action/guest` — Bulk action guest overview (PVE 9.0+)
- `POST /cluster/bulk-action/guest/start` — Bulk start guests (PVE 9.0+)
- `POST /cluster/bulk-action/guest/shutdown` — Bulk shutdown guests (PVE 9.0+)
- `POST /cluster/bulk-action/guest/suspend` — Bulk suspend guests (PVE 9.0+)
- `POST /cluster/bulk-action/guest/migrate` — Bulk migrate guests (PVE 9.0+)

### Bug fixes / corrections
- **`coverage/coverage.ex` bug from Sprint 4.9.10**: The `get_endpoint_info/1` fix (selecting most specific pattern by param_count) remained in place and continues to prevent `status/{command}` from shadowing `status/current`.
- **SDN vnet IPs**: EndpointMatrix shows `POST|PUT|DELETE` (no GET). Fixed coverage entry and router to match — `GET` removed from `/vnets/{vnet}/ips`.
- **Bulk-action action names**: EndpointMatrix uses `start`, `shutdown`, `suspend`, `migrate` (not `startnow`/`stopnow`/etc.). Corrected to match.

### Tests

New test file: `test/mock_pve_api/handlers/sprint_11_test.exs` (45 tests)
- VM status index, console stubs, cloudinit GET/PUT
- LXC status index, console stubs, interfaces
- Node scan (index + types), services actions, replication stubs
- Cluster tasks, HA manager_status + migrate/relocate, metrics/export
- SDN vnet IPs (POST/PUT/DELETE), bulk-action/guest (9.0+)

Updated `test/mock_pve_api/coverage_test.exs`:
- Added ~22 new POST-only paths to `action_endpoints` exception list
- Added `/cluster/sdn/vnets/{vnet}/ips` to both `action_endpoints` and `put_only_actions` lists

## Quality Gates

```
mix compile --warnings-as-errors  → OK
mix format --check-formatted      → OK
mix pve.coverage_diff --summary   → 510 entries, 0 method mismatches
mix test                          → 966 tests, 0 failures
```
