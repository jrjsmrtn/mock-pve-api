# Sprint 4.9.5 - Restore, Monitoring & Misc

**Sprint Duration**: 1 day
**Sprint Goal**: Implement backup restore, VM/CT rrddata, pending config, disk resize, and replication endpoints
**Start Date**: 2026-02-19
**End Date**: 2026-02-19
**Version**: v0.4.9

## Sprint Objective

pvex uses backup restore endpoints, VM/CT monitoring data, pending configuration views, disk resize operations, and replication job management. This sprint adds full stateful support for these.

## Completed Work

### State Management
- Added 1 new state key: `:replication_jobs`
- Added 5 client API functions: `resize_vm_disk`, `resize_container_disk`, `list_replication_jobs`, `create_replication_job`, `get_replication_job`
- Corresponding `handle_call` callbacks for VM/CT resize and replication CRUD

### Handler Modules
- Extended `MockPveApi.Handlers.Nodes` with 7 new functions:
  - `get_vzdump_extractconfig` - returns mock extracted backup config
  - `qmrestore` - VM restore returning UPID
  - `vzrestore` - container restore returning UPID
  - `get_vm_pending` - pending VM config changes
  - `get_container_pending` - pending container config changes
  - `resize_vm_disk` - resize VM disk via State
  - `resize_container_disk` - resize container disk via State
- Extended `MockPveApi.Handlers.Metrics` with 2 new functions:
  - `get_vm_rrd_data` - VM RRD statistics (JSON format)
  - `get_container_rrd_data` - container RRD statistics (JSON format)
- Extended `MockPveApi.Handlers.Cluster` with 2 new functions:
  - `list_replication_jobs` - list all replication jobs
  - `create_replication_job` - create a new replication job

### Router
- Added 3 backup/restore routes: GET vzdump/extractconfig, POST qmrestore, POST vzrestore
- Added 4 VM routes: GET pending, PUT resize, GET rrddata (before rrd)
- Added 4 container routes: GET pending, PUT resize, GET rrddata (before rrd)
- Added 2 replication routes: GET/POST /cluster/replication
- Route ordering: rrddata routes before rrd routes, pending/resize before status/current

### Coverage Modules
- Updated `Coverage.Backup`: moved qmrestore, vzrestore, vzdump/extractconfig from planned to implemented; removed unused `planned/4` and `methods_for/1` helpers
- Updated `Coverage.Monitoring`: moved VM/CT rrddata from planned to implemented
- Updated `Coverage.VMs`: moved pending, resize from planned to implemented
- Updated `Coverage.Containers`: moved pending, resize from planned to implemented
- Updated `Coverage.Cluster`: moved replication from planned to implemented

### Tests
- Extended `nodes_test.exs` with 18 new router integration tests:
  - extractconfig (2), qmrestore (2), vzrestore (2), VM pending (2), CT pending (2), VM resize (2), CT resize (2), VM rrddata (2), CT rrddata (2)
- Extended `cluster_test.exs` with 4 new router integration tests:
  - replication list (1), create+list (1), duplicate (1), missing ID (1)
- Updated `coverage_test.exs`: added resize to put_only_actions, relaxed planned vs implemented assertion

## Endpoint Summary

| Endpoint | Methods | Domain |
|----------|---------|--------|
| `/nodes/{node}/vzdump/extractconfig` | GET | Backup |
| `/nodes/{node}/qmrestore` | POST | Backup |
| `/nodes/{node}/vzrestore` | POST | Backup |
| `/nodes/{node}/qemu/{vmid}/rrddata` | GET | Monitoring |
| `/nodes/{node}/lxc/{vmid}/rrddata` | GET | Monitoring |
| `/nodes/{node}/qemu/{vmid}/pending` | GET | VMs |
| `/nodes/{node}/qemu/{vmid}/resize` | PUT | VMs |
| `/nodes/{node}/lxc/{vmid}/pending` | GET | Containers |
| `/nodes/{node}/lxc/{vmid}/resize` | PUT | Containers |
| `/cluster/replication` | GET, POST | Cluster |

## Test Results

- **686 tests, 0 failures** (up from 664 in Sprint 4.9.4)
- **118 implemented endpoints** (up from 108)
- Zero compiler warnings
- All formatting checks pass
