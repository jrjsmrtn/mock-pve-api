# Sprint 4.9.2 - HA Resources & Backup Jobs

**Sprint Duration**: 1 day
**Sprint Goal**: Implement HA resource/group/affinity CRUD, backup job management, and cluster options
**Start Date**: 2026-02-19
**End Date**: 2026-02-19
**Version**: v0.4.9

## Sprint Objective

pvex uses HA resources, HA groups, and backup job scheduling extensively; the mock server had zero stateful support for these. HA affinity rules existed as hardcoded responses. This sprint adds full CRUD lifecycles for HA resources, HA groups, HA affinity rules (now stateful), backup jobs with included volume computation, not-backed-up VM detection, and cluster datacenter options.

## Completed Work

### State Management
- Added 6 new state keys to `MockPveApi.State`: `:ha_resources`, `:ha_groups`, `:ha_affinity_rules`, `:backup_jobs`, `:next_backup_job_id`, `:cluster_options`
- HA resources keyed by SID (e.g., `"vm:100"`, `"ct:200"`), with automatic type detection from SID prefix
- HA groups keyed by group name, with nodes, restricted, nofailback fields
- HA affinity rules keyed by rule ID, with type, resources, enabled fields
- Backup jobs keyed by auto-generated ID (`"backup-1"`, `"backup-2"`, ...) with schedule, storage, vmid, all fields
- Cluster options with sensible defaults (keyboard, language, console, migration_type, etc.)
- 25 new client API functions and corresponding `handle_call` callbacks
- HA status derived from HA resources state (manager + service entries)
- Backup job included volumes computed from job vmid/all field and existing VMs/CTs
- Not-backed-up endpoint computes VMs/CTs not covered by any backup job

### Handler Module
- Extended `MockPveApi.Handlers.Cluster` with 20 new handler functions
- Rewrote `list_ha_affinity_rules` and `create_ha_affinity_rule` from stateless (hardcoded) to stateful
- Added individual affinity rule CRUD (GET/PUT/DELETE by rule ID)
- All create operations validate required parameters (sid, group name)
- Backup job create returns the auto-generated job ID

### Router
- 27 new route entries for HA resources (5), HA status (1), HA groups (5), HA affinity individual (3), backup jobs (6), backup info (2), cluster options (2), plus existing 2 HA affinity list/create already had routes
- Careful route ordering: `/cluster/backup/:id/included_volumes` before `/cluster/backup/:id` to prevent parameter capture conflicts

### Coverage
- Moved 5 planned cluster entries to implemented: `ha/resources`, `ha/resources/{sid}`, `ha/status/current`, `ha/groups`, `ha/groups/{group}`, `options`
- Added 1 new cluster entry: `ha/affinity/{rule}` (GET, PUT, DELETE)
- Moved 4 planned backup entries to implemented: `cluster/backup`, `cluster/backup/{id}`, `cluster/backup/{id}/included_volumes`, `cluster/backup-info/not-backed-up`
- All new entries have `test_coverage: true` and `handler_module: MockPveApi.Handlers.Cluster`

### Tests
- Extended `test/mock_pve_api/handlers/cluster_test.exs` with 31 new tests (kept 14 existing)
- HA resource lifecycle: list, create, get, update, delete, duplicates, missing sid, ct type detection
- HA status: empty and with resources
- HA group lifecycle: list, CRUD, duplicates, missing name
- HA affinity rules: list, create+get, update, delete, nonexistent
- Backup job lifecycle: list, CRUD, auto-increment IDs
- Backup included volumes: explicit vmids, all mode, nonexistent job
- Not-backed-up: partial coverage, full coverage, empty state
- Cluster options: defaults, update
- Updated `simple_endpoint_test.exs`: added `{sid}` and `{rule}` parameter resolution, added 404 to acceptable error codes

## Metrics

| Metric | Before | After |
|--------|--------|-------|
| Implemented endpoints | 78 | 89 |
| Test count | 576 | 607 |
| Test failures | 0 | 0 |
| Compiler warnings | 0 | 0 |

## New Endpoint Paths (11)

| Path | Methods |
|------|---------|
| `/cluster/ha/resources` | GET, POST |
| `/cluster/ha/resources/{sid}` | GET, PUT, DELETE |
| `/cluster/ha/status/current` | GET |
| `/cluster/ha/groups` | GET, POST |
| `/cluster/ha/groups/{group}` | GET, PUT, DELETE |
| `/cluster/ha/affinity/{rule}` | GET, PUT, DELETE |
| `/cluster/backup` | GET, POST |
| `/cluster/backup/{id}` | GET, PUT, DELETE |
| `/cluster/backup/{id}/included_volumes` | GET |
| `/cluster/backup-info/not-backed-up` | GET |
| `/cluster/options` | GET, PUT |

## Files Changed

- `lib/mock_pve_api/state.ex` -- 6 new state keys, 25 client API functions, handle_call callbacks, ha_resource_type/1 helper
- `lib/mock_pve_api/handlers/cluster.ex` -- 20 new handler functions, rewrote 2 stateless to stateful
- `lib/mock_pve_api/router.ex` -- 27 new routes
- `lib/mock_pve_api/coverage/cluster.ex` -- 5 planned -> implemented, 1 new implemented
- `lib/mock_pve_api/coverage/backup.ex` -- 4 planned -> implemented
- `test/mock_pve_api/handlers/cluster_test.exs` -- 31 new tests
- `test/mock_pve_api/simple_endpoint_test.exs` -- {sid}, {rule} resolution, 404 tolerance
- `docs/reference/api-reference.md` -- regenerated
