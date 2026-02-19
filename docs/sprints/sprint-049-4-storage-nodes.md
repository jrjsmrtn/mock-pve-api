# Sprint 4.9.4 - Storage & Node Advanced

**Sprint Duration**: 1 day
**Sprint Goal**: Implement storage CRUD, volume operations, upload, and node admin endpoints
**Start Date**: 2026-02-19
**End Date**: 2026-02-19
**Version**: v0.4.9

## Sprint Objective

pvex uses storage definition CRUD, individual volume operations, file uploads, and various node admin endpoints (DNS, APT, network interfaces, disks, config, task management). This sprint adds full stateful support for these.

## Completed Work

### State Management
- Added 4 new state keys: `:storage_content`, `:node_dns`, `:node_network_interfaces`, `:node_configs`
- Network interfaces pre-populated for both nodes with eth0 and vmbr0
- Storage CRUD operates on existing `:storage` map (already had "local" and "local-lvm")
- Storage volumes keyed by `{storage_id, volume}` tuple
- Node DNS and config use lazy defaults (returned when no custom value set)
- 14 new client API functions and corresponding `handle_call` callbacks

### Handler Modules
- Extended `MockPveApi.Handlers.Storage` with 7 new functions:
  - `create_storage`, `get_storage`, `update_storage`, `delete_storage`
  - `get_storage_volume`, `delete_storage_volume`, `upload_storage_content`
  - Upload returns a mock UPID task reference
- Extended `MockPveApi.Handlers.Nodes` with 13 new functions:
  - DNS: `get_node_dns`, `update_node_dns`
  - APT: `get_apt_updates`, `post_apt_update`, `get_apt_versions`
  - Network: `get_node_network_iface`, `update_node_network_iface`, `delete_node_network_iface`
  - Disks: `list_disks` (returns realistic mock disk entries)
  - Tasks: `delete_task`
  - Config: `get_node_config`, `update_node_config`
  - Vzdump: `get_vzdump_defaults`

### Router
- Added 6 new storage routes: POST /storage, GET/PUT/DELETE /storage/:storage, GET/DELETE content/:volume, POST upload
- Added 13 new node routes: GET/PUT dns, GET/POST apt/update, GET apt/versions, GET/PUT/DELETE network/:iface, GET disks/list, DELETE tasks/:upid, GET/PUT config, GET vzdump/defaults
- Route ordering: volume routes before content list, iface routes before network list

### Coverage Modules
- Updated `Coverage.Storage`: added POST to storage methods, moved storage/{storage}, content/{volume}, upload from planned to implemented
- Updated `Coverage.Nodes`: moved dns, apt/update, apt/versions, network/{iface}, disks/list, tasks/{upid}, config from planned to implemented
- Updated `Coverage.Backup`: moved vzdump/defaults from planned to implemented

### Tests
- Extended `storage_test.exs` with 7 new router integration tests: storage CRUD (6), upload (1)
- Extended `nodes_test.exs` with 14 new router integration tests: DNS (2), APT (3), network iface (5), disks (1), task delete (2), config (2), vzdump defaults (1)

## Endpoint Summary

| Endpoint | Methods | Domain |
|----------|---------|--------|
| `/storage` | POST (added) | Storage |
| `/storage/{storage}` | GET, PUT, DELETE | Storage |
| `/nodes/{node}/storage/{storage}/content/{volume}` | GET, DELETE | Storage |
| `/nodes/{node}/storage/{storage}/upload` | POST | Storage |
| `/nodes/{node}/vzdump/defaults` | GET | Backup |
| `/nodes/{node}/dns` | GET, PUT | Nodes |
| `/nodes/{node}/apt/update` | GET, POST | Nodes |
| `/nodes/{node}/apt/versions` | GET | Nodes |
| `/nodes/{node}/network/{iface}` | GET, PUT, DELETE | Nodes |
| `/nodes/{node}/disks/list` | GET | Nodes |
| `/nodes/{node}/tasks/{upid}` | DELETE | Nodes |
| `/nodes/{node}/config` | GET, PUT | Nodes |

## Test Results

- **664 tests, 0 failures** (up from 641 in Sprint 4.9.3)
- **108 implemented endpoints** (up from 97)
- Zero compiler warnings
- All formatting checks pass
