# Sprint 4.9.13 — Access Stubs, Cluster Config/Ceph/HA/SDN, Node Ceph/Disks/SDN

**Version**: v0.4.19
**Date**: 2026-03-03
**Status**: Complete

## Summary

Closed all 106 remaining coverage gaps against the EndpointMatrix (5 access, 27 cluster, 74 nodes).
Achieved **0 missing endpoints** in coverage_diff for the first time.

## Coverage Delta

- **Before**: 430 endpoints (v0.4.18, ~65% of EndpointMatrix, 106 missing)
- **After**: 674 catalog entries, 0 missing from EndpointMatrix, 0 method mismatches
- **New tests**: 52 (1007 → 1059)

## Changes

### Access Stubs (5 new entries)

- `GET /access` — navigation index
- `GET /access/openid` — OpenID index
- `POST /access/openid/auth-url` — get OAuth2 auth URL
- `POST /access/openid/login` — OpenID login callback
- `POST /access/vncticket` — create VNC ticket

### Cluster Config Stubs (3 new entries)

- `GET /cluster/config/apiversion`
- `GET /cluster/config/qdevice`
- `GET /cluster/config/totem`

### Cluster Ceph Flags (1 new entry)

- `GET/PUT /cluster/ceph/flags/{flag}` — per-flag getter/setter

### Cluster HA Rules CRUD (2 new entries, State CRUD added)

- `GET/POST /cluster/ha/rules`
- `GET/PUT/DELETE /cluster/ha/rules/{rule}`

New State functions: `list_ha_rules/0`, `get_ha_rule/1`, `create_ha_rule/2`,
`update_ha_rule/2`, `delete_ha_rule/1` + handle_call clauses.

### SDN Fabrics + Lock/Rollback/IPAM (10 new entries in sdn.ex)

- `GET /cluster/sdn/fabrics` and `/fabrics/all`
- `GET/POST /cluster/sdn/fabrics/fabric`
- `GET/PUT/DELETE /cluster/sdn/fabrics/fabric/{id}`
- `GET /cluster/sdn/fabrics/node`
- `GET/POST /cluster/sdn/fabrics/node/{fabric_id}`
- `GET/PUT/DELETE /cluster/sdn/fabrics/node/{fabric_id}/{node_id}`
- `POST/DELETE /cluster/sdn/lock`
- `POST /cluster/sdn/rollback`
- `GET /cluster/sdn/ipams/{ipam}/status`

### Cluster Mapping (entries in cluster.ex; also in hardware.ex)

- `GET/POST /cluster/mapping/pci`, `/pci/{id}`
- `GET/POST /cluster/mapping/usb`, `/usb/{id}`
- `GET/POST /cluster/mapping/dir`, `/dir/{id}`

### Hardware Coverage (4 new entries in hardware.ex)

- `GET /nodes/{node}/hardware` — index
- `GET /nodes/{node}/hardware/pci/{pciid}/mdev`
- `GET /nodes/{node}/hardware/pci/{pci-id-or-mapping}` — matrix duplicate variant
- `GET /nodes/{node}/hardware/pci/{pci-id-or-mapping}/mdev`

### Node Stubs (~80 new entries across nodes.ex + storage.ex + vms.ex)

**Misc node actions**:
- `GET/POST /nodes/{node}/aplinfo`
- `POST /nodes/{node}/vncshell`
- `GET /nodes/{node}/query-url-metadata`
- `GET /nodes/{node}/query-oci-repo-tags`

**Disk sub-routes**:
- `GET /nodes/{node}/disks` (index)
- `DELETE /nodes/{node}/disks/lvm/{name}`
- `DELETE /nodes/{node}/disks/lvmthin/{name}`
- `PUT /nodes/{node}/disks/wipedisk`
- `GET/DELETE /nodes/{node}/disks/zfs/{name}`

**Storage sub-items** (added to storage.ex):
- `GET /nodes/{node}/storage/{storage}` (node-specific index)
- `POST /nodes/{node}/storage/{storage}/download-url`
- `GET /nodes/{node}/storage/{storage}/import-metadata`
- `POST /nodes/{node}/storage/{storage}/oci-registry-pull`

**Node SDN local** (12 new routes):
- `GET /nodes/{node}/sdn`
- `GET /nodes/{node}/sdn/fabrics/{fabric}` and sub-routes (interfaces, neighbors, routes)
- `GET /nodes/{node}/sdn/vnets/{vnet}` and `/mac-vrf`
- `GET /nodes/{node}/sdn/zones`, `/{zone}`, `/{zone}/bridges`, `/{zone}/content`, `/{zone}/ip-vrf`

**Node Ceph** (~40 new entries):
- Index, cfg (4 paths), cmd-safety, config, configdb, crush
- fs (GET + `{name}` POST), init, log
- mds (GET + `{name}` POST/DELETE)
- mgr (GET + `{id}` POST/DELETE)
- mon (GET + `{monid}` POST/DELETE)
- osd/{osdid} (GET/DELETE), in, out, scrub, lv-info, metadata
- pool (GET/POST), pool/{name} (GET/PUT/DELETE), pool/{name}/status
- pools/{name} (GET/PUT/DELETE) — legacy plural path
- restart, start, stop, rules

**VM sub-route** (in vms.ex):
- `POST /nodes/{node}/qemu/{vmid}/dbus-vmstate`

## Files Modified

| File | Change |
|------|--------|
| `lib/mock_pve_api/state.ex` | ha_rules CRUD (public API + handle_call) |
| `lib/mock_pve_api/handlers/access.ex` | 5 new handlers |
| `lib/mock_pve_api/handlers/cluster.ex` | config stubs, ceph flag, ha rules, SDN fabrics/lock/rollback/ipam |
| `lib/mock_pve_api/handlers/nodes.ex` | aplinfo, vncshell, query, disks, SDN, ceph (~80 handlers) |
| `lib/mock_pve_api/handlers/hardware.ex` | hardware index, pci mdev |
| `lib/mock_pve_api/router.ex` | ~80 new routes |
| `lib/mock_pve_api/coverage/access.ex` | 5 entries + implemented helper |
| `lib/mock_pve_api/coverage/cluster.ex` | 14 new entries |
| `lib/mock_pve_api/coverage/hardware.ex` | 4 new entries |
| `lib/mock_pve_api/coverage/nodes.ex` | ~55 new entries |
| `lib/mock_pve_api/coverage/sdn.ex` | 10 new entries + implemented helper |
| `lib/mock_pve_api/coverage/storage.ex` | 4 new storage sub-item entries |
| `lib/mock_pve_api/coverage/vms.ex` | dbus-vmstate entry |
| `test/mock_pve_api/coverage_test.exs` | action_endpoints + put_only_actions updated |
| `mix.exs` | 0.4.18 → 0.4.19 |

## Files Created

| File | Purpose |
|------|---------|
| `test/mock_pve_api/handlers/sprint_13_test.exs` | 52 new endpoint tests |
| `docs/sprints/sprint-049-13-access-cluster-node-stubs.md` | This doc |

## Verification

```
mix pve.coverage_diff --summary
# EndpointMatrix: 658 endpoints
# Coverage catalog: 674 endpoints
# Missing from coverage: 0
# Extra in coverage: 16
# Method mismatches: 0

mix test
# 1059 tests, 0 failures
```
