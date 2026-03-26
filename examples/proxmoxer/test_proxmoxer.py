#!/usr/bin/env python3
"""
Proxmoxer integration test against mock-pve-api.

Exercises standard proxmoxer operations to validate mock API compatibility:
  - Authentication (ticket-based)
  - Node listing and status
  - VM lifecycle (list, create, get config, delete)
  - Container listing
  - Storage listing and content
  - Cluster status and resources
  - Resource pools
  - Version-specific features (SDN, backup providers)
  - API token authentication

Requirements:
    pip install proxmoxer requests

Usage:
    # Start mock server first (HTTP mode for simplicity):
    #   mix run --no-halt
    # Or with SSL:
    #   MOCK_PVE_SSL_ENABLED=true mix run --no-halt

    # Run against HTTPS (default, matching proxmoxer's default):
    PVE_HOST=localhost PVE_PORT=8006 python3 examples/proxmoxer/test_proxmoxer.py

    # Optionally set PVE version to test version-specific features:
    MOCK_PVE_VERSION=9.0 mix run --no-halt
"""

import os
import sys
import traceback

from proxmoxer import ProxmoxAPI

# -- Configuration -----------------------------------------------------------

PVE_HOST = os.getenv("PVE_HOST", "localhost")
PVE_PORT = int(os.getenv("PVE_PORT", "8006"))
PVE_USER = os.getenv("PVE_USER", "root@pam")
PVE_PASSWORD = os.getenv("PVE_PASSWORD", "secret")

# -- Helpers -----------------------------------------------------------------

passed = 0
failed = 0
skipped = 0
errors = []

RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
BLUE = "\033[0;34m"
NC = "\033[0m"


def ok(msg):
    global passed
    passed += 1
    print(f"  {GREEN}PASS{NC}  {msg}")


def fail(msg, detail=""):
    global failed
    failed += 1
    errors.append((msg, detail))
    print(f"  {RED}FAIL{NC}  {msg}")
    if detail:
        print(f"        {detail}")


def skip(msg):
    global skipped
    skipped += 1
    print(f"  {YELLOW}SKIP{NC}  {msg}")


def section(title):
    print(f"\n{BLUE}--- {title} ---{NC}")


# -- Connect ----------------------------------------------------------------

section("Authentication")
try:
    pve = ProxmoxAPI(
        PVE_HOST,
        port=PVE_PORT,
        user=PVE_USER,
        password=PVE_PASSWORD,
        verify_ssl=False,
    )
    ok("Ticket authentication succeeded")
except Exception as e:
    fail("Ticket authentication", str(e))
    print("\nCannot continue without authentication. Is the mock server running?")
    print(f"  Expected: https://{PVE_HOST}:{PVE_PORT}")
    sys.exit(1)

# -- Version -----------------------------------------------------------------

section("Version")
try:
    ver = pve.version.get()
    version_str = ver.get("version", "unknown")
    release = ver.get("release", "unknown")
    ok(f"GET /version  version={version_str}  release={release}")
except Exception as e:
    fail("GET /version", str(e))
    version_str = "8.3"  # fallback for later tests

# Parse major.minor for feature gating
try:
    parts = version_str.split(".")
    ver_major = int(parts[0])
    ver_minor = int(parts[1].split("-")[0]) if len(parts) > 1 else 0
except ValueError:
    ver_major, ver_minor = 8, 3

# -- Cluster -----------------------------------------------------------------

section("Cluster")

try:
    status = pve.cluster.status.get()
    assert isinstance(status, list), f"expected list, got {type(status)}"
    ok(f"GET /cluster/status  items={len(status)}")
except Exception as e:
    fail("GET /cluster/status", str(e))

try:
    resources = pve.cluster.resources.get()
    assert isinstance(resources, list), f"expected list, got {type(resources)}"
    types = set(r.get("type") for r in resources)
    ok(f"GET /cluster/resources  items={len(resources)}  types={types}")
except Exception as e:
    fail("GET /cluster/resources", str(e))

try:
    opts = pve.cluster.options.get()
    ok(f"GET /cluster/options  keys={list(opts.keys()) if isinstance(opts, dict) else '?'}")
except Exception as e:
    fail("GET /cluster/options", str(e))

# -- Nodes -------------------------------------------------------------------

section("Nodes")

try:
    nodes = pve.nodes.get()
    assert isinstance(nodes, list) and len(nodes) >= 1, "expected at least 1 node"
    node_name = nodes[0]["node"]
    ok(f"GET /nodes  count={len(nodes)}  first={node_name}")
except Exception as e:
    fail("GET /nodes", str(e))
    node_name = "pve-node1"  # fallback

node = pve.nodes(node_name)

try:
    time_info = node.time.get()
    ok(f"GET /nodes/{node_name}/time  timezone={time_info.get('timezone', '?')}")
except Exception as e:
    fail(f"GET /nodes/{node_name}/time", str(e))

try:
    dns = node.dns.get()
    ok(f"GET /nodes/{node_name}/dns  search={dns.get('search', '?')}")
except Exception as e:
    fail(f"GET /nodes/{node_name}/dns", str(e))

# -- VMs (QEMU) -------------------------------------------------------------

section("VM Lifecycle")

try:
    vms = node.qemu.get()
    assert isinstance(vms, list)
    ok(f"GET /nodes/{node_name}/qemu  count={len(vms)}")
except Exception as e:
    fail(f"GET /nodes/{node_name}/qemu", str(e))
    vms = []

# Create a VM
test_vmid = 999
try:
    result = node.qemu.post(vmid=test_vmid, name="proxmoxer-test", memory=512, cores=1)
    ok(f"POST /nodes/{node_name}/qemu  vmid={test_vmid}  result={result}")
except Exception as e:
    fail(f"POST /nodes/{node_name}/qemu (create vmid={test_vmid})", str(e))

# Get VM config
try:
    config = node.qemu(test_vmid).config.get()
    assert isinstance(config, dict)
    ok(f"GET /nodes/{node_name}/qemu/{test_vmid}/config  name={config.get('name', '?')}")
except Exception as e:
    fail(f"GET /nodes/{node_name}/qemu/{test_vmid}/config", str(e))

# Get VM status
try:
    status = node.qemu(test_vmid).status.current.get()
    ok(f"GET /nodes/{node_name}/qemu/{test_vmid}/status/current  status={status.get('status', '?')}")
except Exception as e:
    fail(f"GET /nodes/{node_name}/qemu/{test_vmid}/status/current", str(e))

# List VMs again to confirm creation
try:
    vms_after = node.qemu.get()
    found = any(vm.get("vmid") == test_vmid for vm in vms_after)
    if found:
        ok(f"VM {test_vmid} appears in listing after creation")
    else:
        fail(f"VM {test_vmid} not found in listing after creation")
except Exception as e:
    fail(f"GET /nodes/{node_name}/qemu (after create)", str(e))

# Delete VM
try:
    result = node.qemu(test_vmid).delete()
    ok(f"DELETE /nodes/{node_name}/qemu/{test_vmid}  result={result}")
except Exception as e:
    fail(f"DELETE /nodes/{node_name}/qemu/{test_vmid}", str(e))

# -- Containers (LXC) -------------------------------------------------------

section("Containers")

try:
    cts = node.lxc.get()
    assert isinstance(cts, list)
    ok(f"GET /nodes/{node_name}/lxc  count={len(cts)}")
except Exception as e:
    fail(f"GET /nodes/{node_name}/lxc", str(e))

# -- Storage -----------------------------------------------------------------

section("Storage")

try:
    storages = node.storage.get()
    assert isinstance(storages, list)
    ok(f"GET /nodes/{node_name}/storage  count={len(storages)}")
    storage_name = storages[0]["storage"] if storages else "local"
except Exception as e:
    fail(f"GET /nodes/{node_name}/storage", str(e))
    storage_name = "local"

try:
    content = node.storage(storage_name).content.get()
    assert isinstance(content, list)
    ok(f"GET /nodes/{node_name}/storage/{storage_name}/content  items={len(content)}")
except Exception as e:
    fail(f"GET /nodes/{node_name}/storage/{storage_name}/content", str(e))

# Cluster-level storage
try:
    cluster_storage = pve.storage.get()
    assert isinstance(cluster_storage, list)
    ok(f"GET /storage  count={len(cluster_storage)}")
except Exception as e:
    fail("GET /storage", str(e))

# -- Resource Pools ----------------------------------------------------------

section("Pools")

try:
    pools = pve.pools.get()
    assert isinstance(pools, list)
    ok(f"GET /pools  count={len(pools)}")
except Exception as e:
    fail("GET /pools", str(e))

# Create a pool
try:
    pve.pools.post(poolid="proxmoxer-test", comment="test pool")
    ok("POST /pools  poolid=proxmoxer-test")
except Exception as e:
    fail("POST /pools (create)", str(e))

# Get pool
try:
    pool = pve.pools("proxmoxer-test").get()
    ok(f"GET /pools/proxmoxer-test  comment={pool.get('comment', '?')}")
except Exception as e:
    fail("GET /pools/proxmoxer-test", str(e))

# Delete pool
try:
    pve.pools("proxmoxer-test").delete()
    ok("DELETE /pools/proxmoxer-test")
except Exception as e:
    fail("DELETE /pools/proxmoxer-test", str(e))

# -- Access ------------------------------------------------------------------

section("Access")

try:
    users = pve.access.users.get()
    assert isinstance(users, list)
    ok(f"GET /access/users  count={len(users)}")
except Exception as e:
    fail("GET /access/users", str(e))

try:
    roles = pve.access.roles.get()
    assert isinstance(roles, list)
    ok(f"GET /access/roles  count={len(roles)}")
except Exception as e:
    fail("GET /access/roles", str(e))

try:
    domains = pve.access.domains.get()
    assert isinstance(domains, list)
    ok(f"GET /access/domains  count={len(domains)}")
except Exception as e:
    fail("GET /access/domains", str(e))

try:
    acl = pve.access.acl.get()
    assert isinstance(acl, list)
    ok(f"GET /access/acl  count={len(acl)}")
except Exception as e:
    fail("GET /access/acl", str(e))

# -- HA ----------------------------------------------------------------------

section("HA")

try:
    ha_resources = pve.cluster.ha.resources.get()
    assert isinstance(ha_resources, list)
    ok(f"GET /cluster/ha/resources  count={len(ha_resources)}")
except Exception as e:
    fail("GET /cluster/ha/resources", str(e))

try:
    ha_groups = pve.cluster.ha.groups.get()
    assert isinstance(ha_groups, list)
    ok(f"GET /cluster/ha/groups  count={len(ha_groups)}")
except Exception as e:
    fail("GET /cluster/ha/groups", str(e))

# -- Backup ------------------------------------------------------------------

section("Backup")

try:
    backups = pve.cluster.backup.get()
    assert isinstance(backups, list)
    ok(f"GET /cluster/backup  count={len(backups)}")
except Exception as e:
    fail("GET /cluster/backup", str(e))

# -- Version-Specific Features -----------------------------------------------

section("Version-Specific Features")

# SDN (8.0+)
if ver_major > 8 or (ver_major == 8 and ver_minor >= 0):
    try:
        zones = pve.cluster.sdn.zones.get()
        assert isinstance(zones, list)
        ok(f"GET /cluster/sdn/zones (8.0+)  count={len(zones)}")
    except Exception as e:
        fail("GET /cluster/sdn/zones", str(e))

    try:
        vnets = pve.cluster.sdn.vnets.get()
        assert isinstance(vnets, list)
        ok(f"GET /cluster/sdn/vnets (8.0+)  count={len(vnets)}")
    except Exception as e:
        fail("GET /cluster/sdn/vnets", str(e))
else:
    skip(f"SDN features require PVE 8.0+, got {version_str}")

# Backup providers (8.2+)
if ver_major > 8 or (ver_major == 8 and ver_minor >= 2):
    try:
        providers = pve.cluster("backup-info").providers.get()
        assert isinstance(providers, list)
        ok(f"GET /cluster/backup-info/providers (8.2+)  count={len(providers)}")
    except Exception as e:
        fail("GET /cluster/backup-info/providers", str(e))
else:
    skip(f"Backup providers require PVE 8.2+, got {version_str}")

# Notifications (8.1+)
if ver_major > 8 or (ver_major == 8 and ver_minor >= 1):
    try:
        endpoints = pve.cluster.notifications.endpoints.get()
        ok(f"GET /cluster/notifications/endpoints (8.1+)")
    except Exception as e:
        fail("GET /cluster/notifications/endpoints", str(e))
else:
    skip(f"Notifications require PVE 8.1+, got {version_str}")

# HA affinity (9.0+)
if ver_major >= 9:
    try:
        affinity = pve.cluster.ha.affinity.get()
        assert isinstance(affinity, list)
        ok(f"GET /cluster/ha/affinity (9.0+)  count={len(affinity)}")
    except Exception as e:
        fail("GET /cluster/ha/affinity", str(e))
else:
    skip(f"HA affinity requires PVE 9.0+, got {version_str}")

# -- API Token Auth ----------------------------------------------------------

section("API Token Authentication")
try:
    pve_token = ProxmoxAPI(
        PVE_HOST,
        port=PVE_PORT,
        user=PVE_USER,
        token_name="test",
        token_value="secret-token-value",
        verify_ssl=False,
    )
    ver2 = pve_token.version.get()
    ok(f"API token auth  version={ver2.get('version', '?')}")
except Exception as e:
    fail("API token authentication", str(e))

# -- Firewall ----------------------------------------------------------------

section("Firewall")

try:
    fw_options = pve.cluster.firewall.options.get()
    assert isinstance(fw_options, dict)
    ok(f"GET /cluster/firewall/options  keys={list(fw_options.keys())[:5]}")
except Exception as e:
    fail("GET /cluster/firewall/options", str(e))

try:
    fw_rules = pve.cluster.firewall.rules.get()
    assert isinstance(fw_rules, list)
    ok(f"GET /cluster/firewall/rules  count={len(fw_rules)}")
except Exception as e:
    fail("GET /cluster/firewall/rules", str(e))

try:
    fw_aliases = pve.cluster.firewall.aliases.get()
    assert isinstance(fw_aliases, list)
    ok(f"GET /cluster/firewall/aliases  count={len(fw_aliases)}")
except Exception as e:
    fail("GET /cluster/firewall/aliases", str(e))

# -- Summary -----------------------------------------------------------------

print(f"\n{'=' * 50}")
total = passed + failed + skipped
print(f"  {GREEN}{passed} passed{NC}, {RED}{failed} failed{NC}, {YELLOW}{skipped} skipped{NC}  (total {total})")

if errors:
    print(f"\n{RED}Failures:{NC}")
    for msg, detail in errors:
        print(f"  - {msg}")
        if detail:
            print(f"    {detail}")

print()
sys.exit(1 if failed else 0)
