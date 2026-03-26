# Sprint 4.9.9 — Navigation Stubs, ACME CRUD, HardwareTest Fix

**Version**: 0.4.14 → 0.4.15
**Date**: 2026-03-03
**Focus**: Coverage gap closure — navigation indices, ACME per-resource CRUD, test stability

---

## Summary

Three high-impact gaps closed in one pass:

1. **HardwareTest flakiness fixed** — version env not restored between tests caused seed-dependent failures
2. **11 cluster navigation index stubs** — trivial GET endpoints returning subdir lists
3. **10 ACME individual-resource endpoints** — GET/PUT/DELETE per-account/plugin + 4 static read-only

**Coverage delta**: +17 entries in catalog (11 nav + 6 ACME)
**New tests**: 22 (cluster_navigation_test.exs)

---

## 1 — HardwareTest Fix

**File**: `test/mock_pve_api/handlers/hardware_test.exs`

**Problem**: `setup` block reset state but did not save/restore `:pve_version` Application env. When `fixtures_test.exs` ran first with a different version (seed-dependent), HardwareTest saw stale env and hardware endpoints returned 501 (require PVE 8.0+).

**Fix**: Added `original_version` save + `on_exit` restore, matching the pattern from `notifications_test.exs`.

---

## 2 — Navigation Index Stubs

11 new `GET` endpoints returning `%{data: [%{subdir: "..."}]}` lists:

| Endpoint | Since | Handler |
|----------|-------|---------|
| `/api2/json/cluster` | 7.0 | `get_cluster_index/1` |
| `/api2/json/cluster/acme` | 7.0 | `get_acme_index/1` |
| `/api2/json/cluster/ceph` | 7.0 | `get_ceph_index/1` |
| `/api2/json/cluster/firewall` | 7.0 | `get_firewall_index/1` |
| `/api2/json/cluster/ha` | 7.0 | `get_ha_index/1` |
| `/api2/json/cluster/ha/status` | 7.0 | `get_ha_status_index/1` |
| `/api2/json/cluster/jobs` | 7.1 | `get_jobs_index/1` |
| `/api2/json/cluster/log` | 7.0 | `get_log_index/1` |
| `/api2/json/cluster/mapping` | 7.0 | `get_mapping_index/1` |
| `/api2/json/cluster/backup-info` | 7.0 | `get_backup_info_index/1` |
| `/api2/json/cluster/bulk-action` | 9.0 | `get_bulk_action_index/1` |

**Files modified**:
- `lib/mock_pve_api/handlers/cluster.ex` — 11 handler functions + private helpers
- `lib/mock_pve_api/router.ex` — 11 new routes in cluster section
- `lib/mock_pve_api/coverage/cluster.ex` — 11 new coverage entries

---

## 3 — ACME Individual Resource CRUD

10 new endpoints using existing `State` ACME functions:

| Endpoint | Methods | Handler |
|----------|---------|---------|
| `/api2/json/cluster/acme/account/:name` | GET, PUT, DELETE | `get_acme_account/1`, `update_acme_account/1`, `delete_acme_account/1` |
| `/api2/json/cluster/acme/plugins/:id` | GET, PUT, DELETE | `get_acme_plugin_by_id/1`, `update_acme_plugin_by_id/1`, `delete_acme_plugin_by_id/1` |
| `/api2/json/cluster/acme/challenge-schema` | GET | `get_acme_challenge_schema/1` |
| `/api2/json/cluster/acme/directories` | GET | `get_acme_directories/1` |
| `/api2/json/cluster/acme/tos` | GET | `get_acme_tos/1` |
| `/api2/json/cluster/acme/meta` | GET | `get_acme_meta/1` |

All State operations were already implemented (`get_acme_account/1`, `update_acme_account/2`, etc.).

**Files modified**:
- `lib/mock_pve_api/handlers/cluster.ex` — 10 handler functions
- `lib/mock_pve_api/router.ex` — 10 new routes before existing ACME list routes
- `lib/mock_pve_api/coverage/cluster.ex` — 6 new coverage entries

**Private helpers added to cluster.ex**:
- `json_ok/2` — standard 200 JSON response
- `json_error/3` — error response with status code
- `atomize_params/1` — convert string keys to atoms

---

## 4 — New Tests

**File**: `test/mock_pve_api/handlers/cluster_navigation_test.exs`

22 tests:
- Navigation index structure (11 tests — one per endpoint)
- Cluster index contains expected subdirs
- Static ACME endpoints return 200 (4 tests)
- ACME account CRUD lifecycle
- ACME account 404 for unknown name
- ACME plugin CRUD lifecycle
- ACME plugin 404 for unknown id
- Version gating: bulk-action returns 501 on PVE 7.4
- Version gating: jobs returns 200 on 7.1+, 501 on 7.0

---

## Files Changed

| File | Type |
|------|------|
| `test/mock_pve_api/handlers/hardware_test.exs` | Modified |
| `lib/mock_pve_api/handlers/cluster.ex` | Modified |
| `lib/mock_pve_api/router.ex` | Modified |
| `lib/mock_pve_api/coverage/cluster.ex` | Modified |
| `mix.exs` | Modified (0.4.14 → 0.4.15) |
| `test/mock_pve_api/handlers/cluster_navigation_test.exs` | Created |
| `docs/sprints/sprint-049-9-navigation-acme-hardwaretest.md` | Created |

---

## Phase 5 Note

Container distribution (multi-arch builds, GHCR versioned tags, cosign signing, release automation) is a separate sprint. To be planned after this sprint ships.
