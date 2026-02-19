# Sprint 4.9.6 - Cluster & Node Firewall

**Sprint Duration**: 1 day
**Sprint Goal**: Implement cluster-level and node-level firewall endpoints (options, rules, security groups, aliases, IP sets)
**Start Date**: 2026-02-19
**End Date**: 2026-02-19
**Version**: v0.4.9

## Sprint Objective

pvex uses ~20 firewall endpoints across cluster, node, and VM/container scopes. This sprint implements the 14 cluster-level and node-level firewall endpoint paths, the largest single gap in the coverage matrix.

## Completed Work

### State Management
- Added 1 new top-level state key: `:firewall` with nested `cluster` and `nodes` sub-keys
- Cluster firewall state: `options`, `rules` (position-indexed list), `groups`, `aliases`, `ipsets`
- Node firewall state: `options`, `rules` (per-node, created on first access)
- Added 2 client API functions: `get_firewall/1`, `update_firewall/2` (scoped by `:cluster` or `{:node, node}`)
- 4 `handle_call` callbacks for cluster/node get and update operations

### Handler Module
- New `MockPveApi.Handlers.Firewall` module with 30 handler functions:
  - Cluster options: `get_cluster_firewall_options`, `update_cluster_firewall_options`
  - Cluster rules: `list_cluster_firewall_rules`, `create_cluster_firewall_rule`, `get_cluster_firewall_rule`, `update_cluster_firewall_rule`, `delete_cluster_firewall_rule`
  - Security groups: `list_security_groups`, `create_security_group`, `get_security_group`, `delete_security_group`, `get_security_group_rule`, `update_security_group_rule`, `delete_security_group_rule`
  - Aliases: `list_aliases`, `create_alias`, `get_alias`, `update_alias`, `delete_alias`
  - IP sets: `list_ipsets`, `create_ipset`, `get_ipset`, `delete_ipset`, `add_ipset_entry`, `get_ipset_entry`, `update_ipset_entry`, `delete_ipset_entry`
  - Node options: `get_node_firewall_options`, `update_node_firewall_options`
  - Node rules: `list_node_firewall_rules`, `create_node_firewall_rule`, `get_node_firewall_rule`, `update_node_firewall_rule`, `delete_node_firewall_rule`

### Router
- Added 32 new routes across 14 endpoint paths:
  - 11 cluster firewall endpoint paths (options, rules, groups, aliases, ipsets)
  - 3 node firewall endpoint paths (options, rules with position CRUD)
- Route ordering: group/{group}/{pos} routes before group/{group} to avoid Plug path conflicts
- CIDR notation in ipset paths uses dash format (e.g., `10.0.0.0-24`) to avoid path separator conflicts

### Coverage Module
- Rewrote `Coverage.Firewall` to split endpoints into implemented and planned sections
- 14 endpoint paths moved from planned to implemented
- Added `implemented/4` helper alongside existing `planned/4`
- Added `:get_post_delete` method combination for ipset/{name} endpoint
- Remaining planned: 3 cluster (refs, macros, log), 2 node (index, log), 11 VM, 11 container

### Tests
- New `firewall_test.exs` with 31 router integration tests:
  - Cluster options (2): get defaults, put update
  - Cluster rules (4): empty list, create+list, individual CRUD, non-existent position
  - Security groups (7): empty list, create+list, get rules, delete, duplicate error, missing name, non-existent group
  - Security group rules (3): CRUD lifecycle, non-existent group, non-existent position
  - Aliases (4): empty list, CRUD lifecycle, duplicate error, non-existent alias
  - IP sets (5): empty list, full CRUD lifecycle with entries, duplicate error, non-existent ipset, non-existent entry
  - Node options (2): get defaults, put update
  - Node rules (4): empty list, create+list, individual CRUD, per-node isolation

## Endpoint Summary

| Endpoint | Methods | Domain |
|----------|---------|--------|
| `/cluster/firewall/options` | GET, PUT | Firewall |
| `/cluster/firewall/rules` | GET, POST | Firewall |
| `/cluster/firewall/rules/{pos}` | GET, PUT, DELETE | Firewall |
| `/cluster/firewall/groups` | GET, POST | Firewall |
| `/cluster/firewall/groups/{group}` | GET, DELETE | Firewall |
| `/cluster/firewall/groups/{group}/{pos}` | GET, PUT, DELETE | Firewall |
| `/cluster/firewall/aliases` | GET, POST | Firewall |
| `/cluster/firewall/aliases/{name}` | GET, PUT, DELETE | Firewall |
| `/cluster/firewall/ipset` | GET, POST | Firewall |
| `/cluster/firewall/ipset/{name}` | GET, POST, DELETE | Firewall |
| `/cluster/firewall/ipset/{name}/{cidr}` | GET, PUT, DELETE | Firewall |
| `/nodes/{node}/firewall/options` | GET, PUT | Firewall |
| `/nodes/{node}/firewall/rules` | GET, POST | Firewall |
| `/nodes/{node}/firewall/rules/{pos}` | GET, PUT, DELETE | Firewall |

## Test Results

- **717 tests, 0 failures** (up from 686 in Sprint 4.9.5)
- **132 implemented endpoints** (up from 118)
- **57.9% coverage** of total endpoint catalog
- Zero compiler warnings
- All formatting checks pass

## Phase 4.9 Summary

Sprint 4.9.6 completes Phase 4.9: Consumer-Driven API Coverage Expansion.

| Sprint | Domain | New Endpoints | Cumulative |
|--------|--------|---------------|------------|
| 4.9.1 | Snapshots | 8 | 79 |
| 4.9.2 | HA + Backup | 11 | 90 |
| 4.9.3 | Access + SDN | 12 | 102 |
| 4.9.4 | Storage + Nodes | 12 | 114 |
| 4.9.5 | Restore + Monitoring | 4 (+ coverage updates) | 118 |
| 4.9.6 | Firewall | 14 | 132 |

**Phase result**: 71 -> 132 implemented endpoints (~86% increase), covering ~69% of what pvex actually calls.
