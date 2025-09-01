#!/usr/bin/env node
/**
 * Example JavaScript/Node.js client for testing Mock PVE API Server.
 * 
 * This script demonstrates how to use the mock server for testing
 * JavaScript-based PVE client libraries.
 * 
 * Requirements:
 *   npm install axios
 * 
 * Usage:
 *   # Start mock server first
 *   podman run -d -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest
 *   
 *   # Run this script
 *   node test-client.js
 */

const axios = require('axios');

class MockPVEClient {
    constructor(host = 'localhost', port = 8006) {
        this.baseURL = `http://${host}:${port}/api2/json`;
        this.client = axios.create({
            baseURL: this.baseURL,
            timeout: 10000,
            validateStatus: status => status < 500 // Accept 4xx as valid responses
        });
    }

    async get(endpoint, params = {}) {
        const response = await this.client.get(endpoint, { params });
        if (response.status >= 400) {
            throw new Error(`HTTP ${response.status}: ${response.data?.errors || 'Request failed'}`);
        }
        return response.data;
    }

    async post(endpoint, data = {}) {
        const response = await this.client.post(endpoint, data);
        if (response.status >= 400) {
            throw new Error(`HTTP ${response.status}: ${response.data?.errors || 'Request failed'}`);
        }
        return response.data;
    }
}

async function testVersionInfo(client) {
    console.log('🔍 Testing version information...');
    const response = await client.get('version');
    
    const versionData = response.data;
    console.log(`  ✅ PVE Version: ${versionData.version || 'Unknown'}`);
    console.log(`  ✅ Release: ${versionData.release || 'Unknown'}`);
    console.log(`  ✅ Repository ID: ${versionData.repoid || 'Unknown'}`);
    
    return versionData;
}

async function testClusterStatus(client) {
    console.log('\n🔍 Testing cluster status...');
    const response = await client.get('cluster/status');
    
    response.data.forEach(item => {
        if (item.type === 'node') {
            console.log(`  ✅ Node: ${item.name} - Status: ${item.status}`);
        } else if (item.type === 'cluster') {
            console.log(`  ✅ Cluster: ${item.name}`);
        }
    });
    
    return response.data;
}

async function testNodesList(client) {
    console.log('\n🔍 Testing nodes list...');
    const response = await client.get('nodes');
    
    response.data.forEach(node => {
        const cpuPercent = ((node.cpu || 0) * 100).toFixed(1);
        const memoryGB = ((node.mem || 0) / (1024 ** 3)).toFixed(1);
        console.log(`  ✅ Node: ${node.node} - Status: ${node.status}`);
        console.log(`     CPU: ${cpuPercent}% - Memory: ${memoryGB}GB`);
    });
    
    return response.data;
}

async function testClusterResources(client) {
    console.log('\n🔍 Testing cluster resources...');
    const response = await client.get('cluster/resources');
    
    const resourceCounts = {};
    
    response.data.forEach(resource => {
        const type = resource.type;
        resourceCounts[type] = (resourceCounts[type] || 0) + 1;
        
        if (type === 'qemu') {
            console.log(`  ✅ VM ${resource.vmid}: ${resource.name} - Status: ${resource.status}`);
        } else if (type === 'lxc') {
            console.log(`  ✅ CT ${resource.vmid}: ${resource.name} - Status: ${resource.status}`);
        } else if (type === 'storage') {
            console.log(`  ✅ Storage: ${resource.storage} - Type: ${resource.plugintype || 'unknown'}`);
        }
    });
    
    console.log('\n  📊 Resource Summary:');
    Object.entries(resourceCounts).forEach(([type, count]) => {
        console.log(`     ${type}: ${count}`);
    });
    
    return response.data;
}

async function testStorageContent(client, node = 'pve-node-1', storage = 'local') {
    console.log(`\n🔍 Testing storage content for ${storage} on ${node}...`);
    
    try {
        const response = await client.get(`nodes/${node}/storage/${storage}/content`);
        
        const contentTypes = {};
        
        response.data.forEach(item => {
            const contentType = item.content;
            contentTypes[contentType] = (contentTypes[contentType] || 0) + 1;
            const sizeGB = ((item.size || 0) / (1024 ** 3)).toFixed(2);
            console.log(`  ✅ ${item.volid} - Type: ${contentType} - Size: ${sizeGB}GB`);
        });
        
        console.log('\n  📊 Content Summary:');
        Object.entries(contentTypes).forEach(([type, count]) => {
            console.log(`     ${type}: ${count}`);
        });
        
    } catch (error) {
        console.log(`  ⚠️  Storage content test failed: ${error.message}`);
    }
}

async function testVersionSpecificFeatures(client, versionData) {
    const version = versionData.version || '8.3';
    console.log(`\n🔍 Testing version-specific features for PVE ${version}...`);
    
    // Test SDN endpoints (available in PVE 8.0+)
    if (version >= '8.0') {
        try {
            console.log('  🔍 Testing SDN zones (PVE 8.0+)...');
            const zonesResponse = await client.get('cluster/sdn/zones');
            console.log(`  ✅ SDN Zones: ${zonesResponse.data.length} zones available`);
            
            console.log('  🔍 Testing SDN vnets (PVE 8.0+)...');
            const vnetsResponse = await client.get('cluster/sdn/vnets');
            console.log(`  ✅ SDN VNets: ${vnetsResponse.data.length} vnets available`);
            
        } catch (error) {
            console.log(`  ⚠️  SDN endpoints test failed: ${error.message}`);
        }
    } else {
        console.log(`  ⏭️  SDN features not available in PVE ${version}`);
    }
    
    // Test backup providers (available in PVE 8.2+)
    if (version >= '8.2') {
        try {
            console.log('  🔍 Testing backup providers (PVE 8.2+)...');
            const providersResponse = await client.get('cluster/backup-info/providers');
            console.log(`  ✅ Backup Providers: ${providersResponse.data.length} providers available`);
        } catch (error) {
            console.log(`  ⚠️  Backup providers test failed: ${error.message}`);
        }
    } else {
        console.log(`  ⏭️  Backup providers not available in PVE ${version}`);
    }
}

async function testResourcePools(client) {
    console.log('\n🔍 Testing resource pools...');
    
    try {
        const response = await client.get('pools');
        
        response.data.forEach(pool => {
            console.log(`  ✅ Pool: ${pool.poolid} - Comment: ${pool.comment || 'No comment'}`);
            if (pool.members) {
                console.log(`     Members: ${pool.members.length}`);
            }
        });
        
        return response.data;
    } catch (error) {
        console.log(`  ⚠️  Resource pools test failed: ${error.message}`);
    }
}

async function main() {
    console.log('🚀 Mock PVE API Client Test (JavaScript)');
    console.log('=' .repeat(40));
    
    const client = new MockPVEClient('localhost', 8006);
    
    try {
        // Test basic endpoints
        const versionData = await testVersionInfo(client);
        await testClusterStatus(client);
        await testNodesList(client);
        await testClusterResources(client);
        await testStorageContent(client);
        await testResourcePools(client);
        
        // Test version-specific features
        await testVersionSpecificFeatures(client, versionData);
        
        console.log('\n' + '='.repeat(40));
        console.log('🎉 All tests completed successfully!');
        console.log('\nMock PVE API Server is working correctly.');
        
    } catch (error) {
        if (error.code === 'ECONNREFUSED') {
            console.log('❌ Error: Could not connect to Mock PVE API Server');
            console.log('\nMake sure the server is running:');
            console.log('  podman run -d -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest');
            process.exit(1);
        } else {
            console.log(`❌ Error: ${error.message}`);
            process.exit(1);
        }
    }
}

// Run the tests
main().catch(error => {
    console.error('Unhandled error:', error);
    process.exit(1);
});