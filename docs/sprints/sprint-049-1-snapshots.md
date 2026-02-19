# Sprint 4.9.1 - VM & Container Snapshots

**Sprint Duration**: 1 day
**Sprint Goal**: Implement full snapshot CRUD for both QEMU VMs and LXC containers
**Start Date**: 2026-02-19
**End Date**: 2026-02-19
**Version**: v0.4.9

## Sprint Objective

pvex uses snapshot CRUD heavily; the mock had zero snapshot support beyond a fire-and-forget POST that only created a task without actual state tracking. This sprint adds a complete snapshot lifecycle: create, list, get, delete, update config, and rollback -- for both VMs and containers.

## Completed Work

### State Management
- Added `:snapshots` map to `MockPveApi.State` initial state, keyed by `{vmid, snapname}` tuples
- Snapshot records include: `name`, `description`, `snaptime`, `snap_order` (monotonic for reliable ordering), `vmstate`, `parent`
- Parent chain automatically maintained on create (points to most recent existing snapshot)
- Delete operation re-parents child snapshots (preserves chain integrity)
- Rollback removes all snapshots newer than the target (by monotonic order)
- 7 new client API functions: `list_snapshots/1`, `get_snapshot/2`, `create_snapshot/3`, `get_snapshot_config/2`, `update_snapshot_config/3`, `delete_snapshot/2`, `rollback_snapshot/2`

### Handler Module
- New `MockPveApi.Handlers.Snapshots` module handling both QEMU and LXC paths
- Resource type detection from request path (`/qemu/` vs `/lxc/`)
- All operations verify the parent VM/container exists before acting on snapshots
- Task creation for create, delete, and rollback operations (matches real PVE behavior)
- Duplicate snapshot name rejection (400)

### Router
- 14 new route entries (7 per resource type: GET list, POST create, GET/DELETE individual, GET/PUT config, POST rollback)
- Replaced old `Nodes.create_vm_snapshot/1` delegation with `Snapshots.create_snapshot/1`

### Coverage
- Moved 3 VM snapshot endpoints from `planned` to `implemented` in `Coverage.VMs`
- Added 4 new container snapshot endpoints as `implemented` in `Coverage.Containers`
- All snapshot endpoints reference `MockPveApi.Handlers.Snapshots` as handler module
- Updated `test_coverage: true` for all snapshot endpoints

### Tests
- 23 new tests in `test/mock_pve_api/handlers/snapshots_test.exs`
- VM snapshot lifecycle: list, create, get, delete, config get/update, rollback
- Container snapshot lifecycle: list, create, get, delete, rollback
- Edge cases: duplicate name rejection, nonexistent VM/container, parent chain maintenance, snapshot isolation between VMIDs
- Updated `coverage_test.exs`: added rollback endpoints to action_endpoints exception list
- Updated `simple_endpoint_test.exs`: added `{snapname}` parameter resolution

## Metrics

| Metric | Before | After |
|--------|--------|-------|
| Implemented endpoints | 71 | 78 |
| Test count | 553 | 576 |
| Test failures | 0 | 0 |
| Compiler warnings | 0 | 0 |

## New Endpoint Paths (8)

| Path | Methods |
|------|---------|
| `/nodes/{node}/qemu/{vmid}/snapshot` | GET (new), POST |
| `/nodes/{node}/qemu/{vmid}/snapshot/{snapname}` | GET, DELETE |
| `/nodes/{node}/qemu/{vmid}/snapshot/{snapname}/config` | GET, PUT |
| `/nodes/{node}/qemu/{vmid}/snapshot/{snapname}/rollback` | POST |
| `/nodes/{node}/lxc/{vmid}/snapshot` | GET, POST |
| `/nodes/{node}/lxc/{vmid}/snapshot/{snapname}` | GET, DELETE |
| `/nodes/{node}/lxc/{vmid}/snapshot/{snapname}/config` | GET, PUT |
| `/nodes/{node}/lxc/{vmid}/snapshot/{snapname}/rollback` | POST |

## Files Changed

- `lib/mock_pve_api/state.ex` -- snapshot state, client API, handle_call callbacks
- `lib/mock_pve_api/handlers/snapshots.ex` -- new handler module
- `lib/mock_pve_api/router.ex` -- 14 new routes, Snapshots alias
- `lib/mock_pve_api/coverage/vms.ex` -- planned -> implemented, new entries
- `lib/mock_pve_api/coverage/containers.ex` -- new implemented entries
- `test/mock_pve_api/handlers/snapshots_test.exs` -- 23 new tests
- `test/mock_pve_api/coverage_test.exs` -- action_endpoints update
- `test/mock_pve_api/simple_endpoint_test.exs` -- {snapname} resolution
- `mix.exs` -- version bump to 0.4.9
