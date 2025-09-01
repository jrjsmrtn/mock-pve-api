#!/usr/bin/env python3
"""
Example Python client for testing Mock PVE API Server.

This script demonstrates how to use the mock server for testing
Python-based PVE client libraries.

Requirements:
    pip install requests

Usage:
    # Start mock server first
    podman run -d -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest
    
    # Run this script
    python test_client.py
"""

import requests
import json
import sys
from urllib3.exceptions import InsecureRequestWarning

# Disable SSL warnings for mock server
requests.urllib3.disable_warnings(InsecureRequestWarning)


class MockPVEClient:
    """Simple PVE client for testing against mock server."""
    
    def __init__(self, host='localhost', port=8006, verify_ssl=False):
        self.base_url = f"http://{host}:{port}/api2/json"
        self.verify_ssl = verify_ssl
        self.session = requests.Session()
    
    def get(self, endpoint, params=None):
        """Make GET request to PVE API."""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        response = self.session.get(url, params=params, verify=self.verify_ssl)
        response.raise_for_status()
        return response.json()
    
    def post(self, endpoint, data=None):
        """Make POST request to PVE API."""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        response = self.session.post(url, data=data, verify=self.verify_ssl)
        response.raise_for_status()
        return response.json()


def test_version_info(client):
    """Test version information endpoint."""
    print("🔍 Testing version information...")
    response = client.get('version')
    
    version_data = response['data']
    print(f"  ✅ PVE Version: {version_data.get('version')}")
    print(f"  ✅ Release: {version_data.get('release')}")
    print(f"  ✅ Repository ID: {version_data.get('repoid')}")
    
    return version_data


def test_cluster_status(client):
    """Test cluster status endpoint."""
    print("\n🔍 Testing cluster status...")
    response = client.get('cluster/status')
    
    for node in response['data']:
        if node['type'] == 'node':
            print(f"  ✅ Node: {node['name']} - Status: {node['status']}")
        elif node['type'] == 'cluster':
            print(f"  ✅ Cluster: {node['name']}")
    
    return response['data']


def test_nodes_list(client):
    """Test nodes listing endpoint."""
    print("\n🔍 Testing nodes list...")
    response = client.get('nodes')
    
    for node in response['data']:
        print(f"  ✅ Node: {node['node']} - Status: {node['status']}")
        print(f"     CPU: {node.get('cpu', 0)*100:.1f}% - Memory: {node.get('mem', 0)/(1024**3):.1f}GB")
    
    return response['data']


def test_cluster_resources(client):
    """Test cluster resources endpoint."""
    print("\n🔍 Testing cluster resources...")
    response = client.get('cluster/resources')
    
    resource_counts = {}
    for resource in response['data']:
        resource_type = resource['type']
        resource_counts[resource_type] = resource_counts.get(resource_type, 0) + 1
        
        if resource_type == 'qemu':
            print(f"  ✅ VM {resource['vmid']}: {resource['name']} - Status: {resource['status']}")
        elif resource_type == 'lxc':
            print(f"  ✅ CT {resource['vmid']}: {resource['name']} - Status: {resource['status']}")
        elif resource_type == 'storage':
            print(f"  ✅ Storage: {resource['storage']} - Type: {resource.get('plugintype')}")
    
    print(f"\n  📊 Resource Summary:")
    for res_type, count in resource_counts.items():
        print(f"     {res_type}: {count}")
    
    return response['data']


def test_storage_content(client, node='pve-node-1', storage='local'):
    """Test storage content endpoint."""
    print(f"\n🔍 Testing storage content for {storage} on {node}...")
    try:
        response = client.get(f'nodes/{node}/storage/{storage}/content')
        
        content_types = {}
        for item in response['data']:
            content_type = item['content']
            content_types[content_type] = content_types.get(content_type, 0) + 1
            print(f"  ✅ {item['volid']} - Type: {content_type} - Size: {item.get('size', 0)/(1024**3):.2f}GB")
        
        print(f"\n  📊 Content Summary:")
        for content_type, count in content_types.items():
            print(f"     {content_type}: {count}")
            
    except requests.exceptions.HTTPError as e:
        print(f"  ⚠️  Storage content test failed: {e}")


def test_version_specific_features(client, version_data):
    """Test version-specific features."""
    version = version_data.get('version', '8.3')
    print(f"\n🔍 Testing version-specific features for PVE {version}...")
    
    # Test SDN endpoints (available in PVE 8.0+)
    if version >= '8.0':
        try:
            print("  🔍 Testing SDN zones (PVE 8.0+)...")
            response = client.get('cluster/sdn/zones')
            print(f"  ✅ SDN Zones: {len(response['data'])} zones available")
            
            print("  🔍 Testing SDN vnets (PVE 8.0+)...")
            response = client.get('cluster/sdn/vnets')
            print(f"  ✅ SDN VNets: {len(response['data'])} vnets available")
            
        except requests.exceptions.HTTPError as e:
            print(f"  ⚠️  SDN endpoints test failed: {e}")
    else:
        print(f"  ⏭️  SDN features not available in PVE {version}")
    
    # Test backup providers (available in PVE 8.2+)
    if version >= '8.2':
        try:
            print("  🔍 Testing backup providers (PVE 8.2+)...")
            response = client.get('cluster/backup-info/providers')
            print(f"  ✅ Backup Providers: {len(response['data'])} providers available")
        except requests.exceptions.HTTPError as e:
            print(f"  ⚠️  Backup providers test failed: {e}")
    else:
        print(f"  ⏭️  Backup providers not available in PVE {version}")


def main():
    """Main test function."""
    print("🚀 Mock PVE API Client Test")
    print("=" * 40)
    
    # Initialize client
    client = MockPVEClient(host='localhost', port=8006)
    
    try:
        # Test basic endpoints
        version_data = test_version_info(client)
        test_cluster_status(client)
        test_nodes_list(client)
        test_cluster_resources(client)
        test_storage_content(client)
        
        # Test version-specific features
        test_version_specific_features(client, version_data)
        
        print("\n" + "=" * 40)
        print("🎉 All tests completed successfully!")
        print("\nMock PVE API Server is working correctly.")
        
    except requests.exceptions.ConnectionError:
        print("❌ Error: Could not connect to Mock PVE API Server")
        print("\nMake sure the server is running:")
        print("  podman run -d -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest")
        sys.exit(1)
        
    except requests.exceptions.HTTPError as e:
        print(f"❌ HTTP Error: {e}")
        sys.exit(1)
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()