# Sprint 4.9.7 - Fix 21 Method Mismatches in Coverage Modules

**Sprint Duration**: 1 day
**Sprint Goal**: Resolve all discrepancies between the EndpointMatrix (ground truth from pve-openapi) and the Coverage catalog — 0 method mismatches
**Start Date**: 2026-03-03
**End Date**: 2026-03-03
**Version**: v0.4.13

## Sprint Objective

`mix pve.coverage_diff` (introduced in v0.4.12) surfaced 21 method mismatches between the
EndpointMatrix (generated from the pve-openapi ground-truth specs) and the Coverage catalog.
The mismatches fell into three groups:

- **Group A**: Phantom methods in Coverage that don't exist in the real API
- **Group B**: Wrong HTTP method in Coverage + router
- **Group C**: Real API methods missing from both Coverage and the router/handlers

This sprint fixes all 21 mismatches and brings the test count from 828 to ~855+.

---

## Completed Work

### Group A — Coverage-only fixes (phantom method removal)

| Endpoint | Fix |
|----------|-----|
| `/nodes/{node}/qemu/{vmid}` | Removed phantom `:put` from `coverage/vms.ex` |
| `/nodes/{node}/lxc/{vmid}` | Removed phantom `:put` from `coverage/containers.ex` |
| `/nodes/{node}/services/{service}/state` | Changed `:put` → `:get` in `coverage/monitoring.ex` |

### Group B — Coverage + router fix

| Endpoint | Fix |
|----------|-----|
| `/cluster/config` | Coverage changed `[:get, :put]` → `[:get, :post]`; router `put` route changed to `post` |

### Group C — Coverage + router + new handler logic

#### Access (`handlers/access.ex`, `coverage/access.ex`)
- **GET `/access/ticket`** — returns static ticket info (username, expire)
- **PUT `/access/tfa`** — no-op update of TFA settings, returns nil
- **POST `/access/tfa/{userid}`** — returns static TFA entry (type, description, id)

#### Cluster (`handlers/cluster.ex`, `coverage/cluster.ex`)
- **GET `/cluster/config/join`** — returns static join parameters (totem, nodelist, preferred_node, config_digest)
- **POST `/cluster/config/nodes/{node}`** — appends node to cluster state, returns UPID

#### Firewall (`handlers/firewall.ex`, `coverage/firewall.ex`)
- **POST `/cluster/firewall/groups/{group}`** — appends a new rule to the group's rules list using the existing `build_rule/1` helper

#### Monitoring (`handlers/metrics.ex`, `coverage/monitoring.ex`, `state.ex`)
- **POST `/cluster/metrics/server/{id}`** — creates an external metrics server config in state
- **PUT `/cluster/metrics/server/{id}`** — updates metrics server config in state
- **DELETE `/cluster/metrics/server/{id}`** — removes metrics server from state
- Updated `list_metrics_servers/1` to read from `State.get_metrics_servers()` instead of returning `[]`

#### SDN (`handlers/sdn.ex`, `coverage/sdn.ex`)
- **PUT `/cluster/sdn`** — no-op apply of pending SDN config, returns nil

#### VMs (`handlers/nodes.ex`, `coverage/vms.ex`)
- **GET `/nodes/{node}/qemu/{vmid}/migrate`** — returns preconditions `{running: false, local_disks: [], local_resources: [], allowed_nodes: []}`
- **POST `/nodes/{node}/qemu/{vmid}/config`** — async config update, returns UPID task string
- **GET `/nodes/{node}/qemu/{vmid}/agent`** — returns `{supported: false}`

#### Containers (`handlers/nodes.ex`, `coverage/containers.ex`)
- **GET `/nodes/{node}/lxc/{vmid}/migrate`** — returns preconditions `{running: false, local_volumes: [], allowed_nodes: []}`

#### Nodes (`handlers/nodes.ex`, `coverage/nodes.ex`)
- **POST `/nodes/{node}/network`** — creates network interface in state
- **PUT `/nodes/{node}/network`** — no-op reload, returns nil
- **DELETE `/nodes/{node}/network`** — no-op revert pending changes, returns nil
- **PUT `/nodes/{node}/subscription`** — no-op key update, returns nil
- **DELETE `/nodes/{node}/subscription`** — no-op key delete, returns nil
- **GET `/nodes/{node}/tasks/{upid}`** — returns task summary struct (upid, type, user, status, exitstatus, starttime, endtime)

#### Storage (`handlers/storage.ex`, `coverage/storage.ex`)
- **POST `/nodes/{node}/storage/{storage}/content/{volume}`** — copy/restore volume, returns UPID
- **PUT `/nodes/{node}/storage/{storage}/content/{volume}`** — update volume attributes (notes, protected), returns nil

---

## State Changes (`state.ex`)

- Added `metrics_servers: %{}` to `initial_state/0`
- Added 5 new client API functions: `get_metrics_servers/0`, `get_metrics_server/1`, `create_metrics_server/2`, `update_metrics_server/2`, `delete_metrics_server/1`
- Added corresponding `handle_call` clauses for all metrics server operations

---

## Files Modified

| File | Nature of change |
|------|-----------------|
| `lib/mock_pve_api/coverage/vms.ex` | Remove phantom `:put`; add `:get` to migrate; add `:post` to config; add `:get` to agent |
| `lib/mock_pve_api/coverage/containers.ex` | Remove phantom `:put`; add `:get` to migrate |
| `lib/mock_pve_api/coverage/monitoring.ex` | Fix services/state `:put`→`:get`; add `:post,:put,:delete` to metrics server |
| `lib/mock_pve_api/coverage/cluster.ex` | Fix config `:put`→`:post`; add `:get` to config/join; add `:post` to config/nodes/{node} |
| `lib/mock_pve_api/coverage/access.ex` | Add `:get` to ticket; add `:put` to tfa; add `:post` to tfa/{userid} |
| `lib/mock_pve_api/coverage/firewall.ex` | Add `:post` to groups/{group} |
| `lib/mock_pve_api/coverage/sdn.ex` | Add `:put` to /cluster/sdn |
| `lib/mock_pve_api/coverage/nodes.ex` | Add `:post,:put,:delete` to network; add `:get` to tasks/{upid}; add `:put,:delete` to subscription |
| `lib/mock_pve_api/coverage/storage.ex` | Add `:post,:put` to content/{volume} |
| `lib/mock_pve_api/router.ex` | Fix `put→post` for cluster/config; add 23 new routes |
| `lib/mock_pve_api/handlers/access.ex` | Add `get_ticket/1`, `update_tfa/1`, `create_tfa_entry/1` |
| `lib/mock_pve_api/handlers/cluster.ex` | Add `get_config_join/1`, `add_cluster_node/1` |
| `lib/mock_pve_api/handlers/firewall.ex` | Add `create_security_group_rule/1` |
| `lib/mock_pve_api/handlers/metrics.ex` | Add `create_metrics_server/1`, `update_metrics_server/1`, `delete_metrics_server/1`; update `list_metrics_servers/1` |
| `lib/mock_pve_api/handlers/sdn.ex` | Add `apply_sdn/1` |
| `lib/mock_pve_api/handlers/nodes.ex` | Add 10 new handler functions |
| `lib/mock_pve_api/handlers/storage.ex` | Add `copy_storage_volume/1`, `update_storage_volume/1` |
| `lib/mock_pve_api/state.ex` | Add `metrics_servers` to state; add 5 client API functions + handle_call clauses |
| `mix.exs` | Bump version 0.4.12 → 0.4.13 |

## Files Created

| File | Purpose |
|------|---------|
| `test/mock_pve_api/method_mismatches_test.exs` | ~27 integration tests for all new and fixed methods |
| `docs/sprints/sprint-049-7-method-mismatches.md` | This sprint document |

---

## Verification

```bash
cd mock-pve-api

mix compile --warnings-as-errors
mix format --check-formatted
mix pve.coverage_diff --summary   # Expected: "Method mismatches: 0"
mix test --seed 12345             # Expected: 855 tests, 0 failures
```

> **Note on test flakiness**: `HardwareTest` is a pre-existing flaky test suite due to
> `fixtures_test.exs` calling `Application.put_env(:mock_pve_api, :pve_version, …)` without
> restoring it. Depending on test ordering (seed), this can leave a sub-8.0 version in the
> application env, causing hardware mapping endpoints (which require 8.0+) to return 501.
> This is unrelated to Sprint 4.9.7 changes. Fix tracked separately.
