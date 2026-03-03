# Sprint 4.9.10 — QEMU Agent Stubs, Realm-Sync CRUD, Dir Mapping

**Date**: 2026-03-03
**Version**: v0.4.15 → v0.4.16
**Branch**: develop

---

## Goals

- Add QEMU agent sub-command routing (25 new coverage entries)
- Add cluster jobs realm-sync CRUD (3 new coverage entries, State + routes + handlers)
- Add cluster mapping/dir CRUD (2 new coverage entries, State + routes + handlers)
- Add ~30 tests across 3 new test files

---

## What Was Done

### 1. QEMU Agent Sub-Commands

**Problem**: Only `GET /agent` and `POST /agent` existed. 25 sub-command endpoints
(e.g., `get-osinfo`, `ping`, `exec`) returned 404.

**Solution**:
- Added `vm_agent_subcommand/1` to `handlers/nodes.ex` — a catch-all handler
  returning `{data: {result: ""}}` for GET and `{data: nil}` for POST.
- Added 2 routes in `router.ex` **before** the existing parameterless agent routes:
  - `GET /api2/json/nodes/:node/qemu/:vmid/agent/:subcommand`
  - `POST /api2/json/nodes/:node/qemu/:vmid/agent/:subcommand`
- Added 25 coverage entries to `coverage/vms.ex` (13 GET + 12 POST sub-commands).

### 2. Cluster Jobs: Realm-Sync CRUD

**Problem**: `/cluster/jobs/realm-sync` and sub-paths returned 404.

**Solution**:
- Added `realm_sync_jobs: %{}` to `State.initial_state/0`.
- Added 5 public API functions + 5 `handle_call` clauses to `state.ex`
  (mirrors the pci_mappings pattern).
- Added 6 handlers to `handlers/cluster.ex`:
  `get_schedule_analyze/1`, `list_realm_sync_jobs/1`, `get_realm_sync_job/1`,
  `create_realm_sync_job/1`, `update_realm_sync_job/1`, `delete_realm_sync_job/1`.
- Added 6 routes to `router.ex` after the jobs index.
- Added 3 coverage entries to `coverage/cluster.ex`.

### 3. Cluster Mapping: Dir CRUD

**Problem**: `/cluster/mapping/dir` not implemented (PCI and USB were already done
  in `handlers/hardware.ex` and `coverage/hardware.ex`).

**Solution**:
- Added `dir_mappings: %{}` to `State.initial_state/0`.
- Added 5 public API functions + 5 `handle_call` clauses to `state.ex`.
- Added 5 handlers to `handlers/hardware.ex` (mirrors pci/usb pattern).
- Added 5 routes to `router.ex` after the USB mapping routes.
- Added 2 coverage entries to `coverage/hardware.ex`.

### 4. Tests

Three new test files:
- `test/mock_pve_api/handlers/agent_test.exs` — 10 tests
- `test/mock_pve_api/handlers/cluster_jobs_test.exs` — 8 tests
- `test/mock_pve_api/handlers/cluster_mapping_test.exs` — 12 tests

---

## Files Modified

| File | Change |
|------|--------|
| `lib/mock_pve_api/state.ex` | `realm_sync_jobs: %{}`, `dir_mappings: %{}` + 10 CRUD functions + 10 handle_call clauses |
| `lib/mock_pve_api/handlers/nodes.ex` | `vm_agent_subcommand/1` |
| `lib/mock_pve_api/handlers/cluster.ex` | 6 realm-sync handlers |
| `lib/mock_pve_api/handlers/hardware.ex` | 5 dir mapping handlers |
| `lib/mock_pve_api/router.ex` | 2 agent routes + 6 realm-sync routes + 5 dir routes |
| `lib/mock_pve_api/coverage/vms.ex` | 25 agent sub-command entries |
| `lib/mock_pve_api/coverage/cluster.ex` | 3 realm-sync entries |
| `lib/mock_pve_api/coverage/hardware.ex` | 2 dir mapping entries |
| `mix.exs` | 0.4.15 → 0.4.16 |

## Files Created

| File | Purpose |
|------|---------|
| `test/mock_pve_api/handlers/agent_test.exs` | 10 agent tests |
| `test/mock_pve_api/handlers/cluster_jobs_test.exs` | 8 realm-sync tests |
| `test/mock_pve_api/handlers/cluster_mapping_test.exs` | 12 mapping tests |

---

## Coverage Delta

| Area | New Entries |
|------|-------------|
| Agent sub-commands (vms.ex) | 25 |
| Realm-sync (cluster.ex) | 3 |
| Dir mapping (hardware.ex) | 2 |
| **Total** | **30** |

Previous: 430 entries → New: ~460 entries

---

## Notes

- PCI and USB mapping routes/handlers/coverage were already present from a
  previous sprint (Sprint 4.9.7). Only dir mapping was new.
- Agent routes use a `:subcommand` segment — must be declared **before** the
  parameterless agent routes to avoid shadowing.
- `create_realm_sync_job` uses `POST /{id}` (PVE convention for realm-sync).
