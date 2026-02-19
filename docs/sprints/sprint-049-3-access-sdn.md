# Sprint 4.9.3 - Access Control & SDN Completion

**Sprint Duration**: 1 day
**Sprint Goal**: Implement domain/role/password CRUD, ACL GET, and full stateful SDN CRUD
**Start Date**: 2026-02-19
**End Date**: 2026-02-19
**Version**: v0.4.9

## Sprint Objective

pvex calls roles CRUD, domains CRUD, password change, ACL read, and full SDN vnet/subnet/controller CRUD. The mock had partial support (list-only for domains/roles, hardcoded SDN). This sprint makes all Access and SDN endpoints fully stateful with CRUD lifecycles.

## Completed Work

### State Management
- Added 4 new state keys to `MockPveApi.State`: `:sdn_zones`, `:sdn_vnets`, `:sdn_subnets`, `:sdn_controllers`
- SDN zones keyed by zone name, with type, nodes, peers, tag, mtu, digest fields
- SDN vnets keyed by vnet name, with zone, tag, alias, digest fields
- SDN subnets keyed by `{vnet, subnet}` tuple, with gateway, snat, dnszoneprefix fields
- SDN controllers keyed by controller name, with type, asn, peers, digest fields
- Cascading delete: deleting a vnet removes all its subnets
- 29 new client API functions: domain CRUD (4), role CRUD (4), password change, ACL GET, SDN zone CRUD (5), vnet CRUD (5), subnet CRUD (5), controller CRUD (5)
- Corresponding `handle_call` callbacks for all new functions

### Handler Modules
- Extended `MockPveApi.Handlers.Access` with 10 new functions:
  - `create_domain`, `get_domain`, `update_domain`, `delete_domain`
  - `get_role`, `create_role`, `update_role`, `delete_role`
  - `change_password`, `get_acl`
  - Role create/update parses comma-separated `privs` string to list
  - ACL GET flattens permissions map into list of structured entries
- Rewrote `MockPveApi.Handlers.Sdn` from stateless to fully stateful:
  - `get_sdn_index` returns sub-resource directory listing
  - Zone CRUD (5 functions), VNet CRUD (5), Subnet CRUD (5), Controller CRUD (5)
  - All functions use State module instead of hardcoded responses

### Router
- Added 12 new access routes: POST domains, GET/PUT/DELETE domains/:realm, GET acl, POST roles, GET/PUT/DELETE roles/:roleid, PUT password
- Rewrote SDN section with 21 routes for full CRUD on all SDN sub-resources
- Subnet routes placed before individual vnet routes to prevent parameter capture conflicts
- Removed standalone `/cluster/sdn/subnets` route (subnets are now under vnets)

### Coverage Modules
- Updated `Coverage.Access`: domains and roles now include POST, `test_coverage: true`; moved roles/{roleid}, domains/{realm}, password from planned to implemented
- Rewrote `Coverage.Sdn`: 9 implemented endpoints (index, zones, vnets, subnets, controllers with individual CRUD); planned reduced to dns and ipams

### Tests
- Extended `access_test.exs` with 19 new tests: domain CRUD (7), role CRUD (8), password change (3), ACL GET (1)
- Rewrote `sdn_test.exs` with 24 tests: SDN index (1), zones (5), vnets (7), subnets (6), controllers (5)
- Updated `router_test.exs` SDN tests for stateful behavior (create resources before GET/PUT/DELETE)
- Updated `simple_endpoint_test.exs` with new parameter resolution entries

### Bug Fixes
- Fixed `Capabilities.endpoint_supported?/2` to check any HTTP method against EndpointMatrix, not just `:get` (was blocking PUT-only endpoints like `/access/password`)
- Fixed SDN subnet CIDR paths using dash format (`10.0.0.0-24`) instead of slash (`10.0.0.0/24`) to avoid path separator conflicts in Plug.Router
- Added `/access/password` to `put_only_actions` in coverage method validation tests

## Endpoint Summary

| Endpoint | Methods | Domain |
|----------|---------|--------|
| `/access/domains` | POST (added) | Access |
| `/access/domains/{realm}` | GET, PUT, DELETE | Access |
| `/access/roles` | POST (added) | Access |
| `/access/roles/{roleid}` | GET, PUT, DELETE | Access |
| `/access/password` | PUT | Access |
| `/access/acl` | GET (added) | Access |
| `/cluster/sdn` | GET | SDN |
| `/cluster/sdn/zones` | POST (added, stateful) | SDN |
| `/cluster/sdn/vnets/{vnet}` | GET, PUT, DELETE | SDN |
| `/cluster/sdn/vnets/{vnet}/subnets` | GET, POST | SDN |
| `/cluster/sdn/vnets/{vnet}/subnets/{subnet}` | GET, PUT, DELETE | SDN |
| `/cluster/sdn/controllers` | GET, POST | SDN |
| `/cluster/sdn/controllers/{controller}` | GET, PUT, DELETE | SDN |

## Test Results

- **641 tests, 0 failures** (up from 617 in Sprint 4.9.2)
- Zero compiler warnings
- All formatting checks pass
