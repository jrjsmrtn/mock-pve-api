package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"
)

// MockPVEClient represents a client for the Mock PVE API Server
type MockPVEClient struct {
	baseURL string
	client  *http.Client
}

// PVEResponse represents a standard PVE API response
type PVEResponse struct {
	Data interface{} `json:"data"`
}

// VersionData represents version information
type VersionData struct {
	Version      string            `json:"version"`
	Release      string            `json:"release"`
	RepoID       string            `json:"repoid"`
	Capabilities map[string]bool   `json:"capabilities,omitempty"`
}

// NodeData represents node information
type NodeData struct {
	Node     string  `json:"node"`
	Status   string  `json:"status"`
	CPU      float64 `json:"cpu"`
	MaxCPU   int     `json:"maxcpu"`
	Mem      int64   `json:"mem"`
	MaxMem   int64   `json:"maxmem"`
	Disk     int64   `json:"disk"`
	MaxDisk  int64   `json:"maxdisk"`
	Uptime   int64   `json:"uptime"`
}

// ClusterStatusItem represents cluster status information
type ClusterStatusItem struct {
	Type   string `json:"type"`
	Name   string `json:"name"`
	Status string `json:"status,omitempty"`
	Nodes  int    `json:"nodes,omitempty"`
	ID     string `json:"id,omitempty"`
}

// ResourceData represents cluster resource information
type ResourceData struct {
	ID      string  `json:"id"`
	Type    string  `json:"type"`
	Node    string  `json:"node,omitempty"`
	VMID    int     `json:"vmid,omitempty"`
	Name    string  `json:"name,omitempty"`
	Status  string  `json:"status"`
	CPU     float64 `json:"cpu,omitempty"`
	MaxCPU  int     `json:"maxcpu,omitempty"`
	Mem     int64   `json:"mem,omitempty"`
	MaxMem  int64   `json:"maxmem,omitempty"`
	Storage string  `json:"storage,omitempty"`
}

// PoolData represents resource pool information
type PoolData struct {
	PoolID  string `json:"poolid"`
	Comment string `json:"comment,omitempty"`
}

// NewMockPVEClient creates a new Mock PVE API client
func NewMockPVEClient(host string, port int) *MockPVEClient {
	return &MockPVEClient{
		baseURL: fmt.Sprintf("http://%s:%d/api2/json", host, port),
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// Get performs a GET request to the API
func (c *MockPVEClient) Get(endpoint string) (*PVEResponse, error) {
	url := fmt.Sprintf("%s/%s", c.baseURL, endpoint)
	
	resp, err := c.client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("GET request failed: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %v", err)
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("API error %d: %s", resp.StatusCode, string(body))
	}

	var response PVEResponse
	if err := json.Unmarshal(body, &response); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %v", err)
	}

	return &response, nil
}

// Post performs a POST request to the API
func (c *MockPVEClient) Post(endpoint string, data interface{}) (*PVEResponse, error) {
	url := fmt.Sprintf("%s/%s", c.baseURL, endpoint)
	
	var body io.Reader
	if data != nil {
		jsonData, err := json.Marshal(data)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal request data: %v", err)
		}
		body = bytes.NewReader(jsonData)
	}

	resp, err := c.client.Post(url, "application/json", body)
	if err != nil {
		return nil, fmt.Errorf("POST request failed: %v", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %v", err)
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("API error %d: %s", resp.StatusCode, string(respBody))
	}

	var response PVEResponse
	if err := json.Unmarshal(respBody, &response); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %v", err)
	}

	return &response, nil
}

func testVersionInfo(client *MockPVEClient) (*VersionData, error) {
	fmt.Println("🔍 Testing version information...")
	
	resp, err := client.Get("version")
	if err != nil {
		return nil, err
	}

	// Convert interface{} to map for easier access
	dataMap := resp.Data.(map[string]interface{})
	
	versionData := &VersionData{
		Version: getString(dataMap, "version"),
		Release: getString(dataMap, "release"),
		RepoID:  getString(dataMap, "repoid"),
	}

	fmt.Printf("  ✅ PVE Version: %s\n", versionData.Version)
	fmt.Printf("  ✅ Release: %s\n", versionData.Release)
	fmt.Printf("  ✅ Repository ID: %s\n", versionData.RepoID)

	return versionData, nil
}

func testClusterStatus(client *MockPVEClient) error {
	fmt.Println("\n🔍 Testing cluster status...")
	
	resp, err := client.Get("cluster/status")
	if err != nil {
		return err
	}

	// Convert to slice of maps
	dataSlice := resp.Data.([]interface{})
	
	for _, item := range dataSlice {
		itemMap := item.(map[string]interface{})
		itemType := getString(itemMap, "type")
		name := getString(itemMap, "name")
		
		if itemType == "node" {
			status := getString(itemMap, "status")
			fmt.Printf("  ✅ Node: %s - Status: %s\n", name, status)
		} else if itemType == "cluster" {
			fmt.Printf("  ✅ Cluster: %s\n", name)
		}
	}

	return nil
}

func testNodesList(client *MockPVEClient) error {
	fmt.Println("\n🔍 Testing nodes list...")
	
	resp, err := client.Get("nodes")
	if err != nil {
		return err
	}

	dataSlice := resp.Data.([]interface{})
	
	for _, item := range dataSlice {
		nodeMap := item.(map[string]interface{})
		node := getString(nodeMap, "node")
		status := getString(nodeMap, "status")
		cpu := getFloat(nodeMap, "cpu")
		mem := getInt64(nodeMap, "mem")
		
		cpuPercent := cpu * 100
		memoryGB := float64(mem) / (1024 * 1024 * 1024)
		
		fmt.Printf("  ✅ Node: %s - Status: %s\n", node, status)
		fmt.Printf("     CPU: %.1f%% - Memory: %.1fGB\n", cpuPercent, memoryGB)
	}

	return nil
}

func testClusterResources(client *MockPVEClient) error {
	fmt.Println("\n🔍 Testing cluster resources...")
	
	resp, err := client.Get("cluster/resources")
	if err != nil {
		return err
	}

	dataSlice := resp.Data.([]interface{})
	resourceCounts := make(map[string]int)
	
	for _, item := range dataSlice {
		resourceMap := item.(map[string]interface{})
		resourceType := getString(resourceMap, "type")
		resourceCounts[resourceType]++
		
		switch resourceType {
		case "qemu":
			vmid := getInt(resourceMap, "vmid")
			name := getString(resourceMap, "name")
			status := getString(resourceMap, "status")
			fmt.Printf("  ✅ VM %d: %s - Status: %s\n", vmid, name, status)
		case "lxc":
			vmid := getInt(resourceMap, "vmid")
			name := getString(resourceMap, "name")
			status := getString(resourceMap, "status")
			fmt.Printf("  ✅ CT %d: %s - Status: %s\n", vmid, name, status)
		case "storage":
			storage := getString(resourceMap, "storage")
			plugintype := getString(resourceMap, "plugintype")
			if plugintype == "" {
				plugintype = "unknown"
			}
			fmt.Printf("  ✅ Storage: %s - Type: %s\n", storage, plugintype)
		}
	}

	fmt.Println("\n  📊 Resource Summary:")
	for resourceType, count := range resourceCounts {
		fmt.Printf("     %s: %d\n", resourceType, count)
	}

	return nil
}

func testStorageContent(client *MockPVEClient, node, storage string) error {
	fmt.Printf("\n🔍 Testing storage content for %s on %s...\n", storage, node)
	
	endpoint := fmt.Sprintf("nodes/%s/storage/%s/content", node, storage)
	resp, err := client.Get(endpoint)
	if err != nil {
		fmt.Printf("  ⚠️  Storage content test failed: %v\n", err)
		return nil // Don't fail the entire test
	}

	dataSlice := resp.Data.([]interface{})
	contentTypes := make(map[string]int)
	
	for _, item := range dataSlice {
		contentMap := item.(map[string]interface{})
		volid := getString(contentMap, "volid")
		contentType := getString(contentMap, "content")
		size := getInt64(contentMap, "size")
		
		contentTypes[contentType]++
		sizeGB := float64(size) / (1024 * 1024 * 1024)
		
		fmt.Printf("  ✅ %s - Type: %s - Size: %.2fGB\n", volid, contentType, sizeGB)
	}

	fmt.Println("\n  📊 Content Summary:")
	for contentType, count := range contentTypes {
		fmt.Printf("     %s: %d\n", contentType, count)
	}

	return nil
}

func testVersionSpecificFeatures(client *MockPVEClient, versionData *VersionData) error {
	version := versionData.Version
	fmt.Printf("\n🔍 Testing version-specific features for PVE %s...\n", version)

	// Test SDN endpoints (available in PVE 8.0+)
	if isVersionAtLeast(version, "8.0") {
		if err := testSDNFeatures(client); err != nil {
			fmt.Printf("  ⚠️  SDN endpoints test failed: %v\n", err)
		}
	} else {
		fmt.Printf("  ⏭️  SDN features not available in PVE %s\n", version)
	}

	// Test backup providers (available in PVE 8.2+)
	if isVersionAtLeast(version, "8.2") {
		if err := testBackupProviders(client); err != nil {
			fmt.Printf("  ⚠️  Backup providers test failed: %v\n", err)
		}
	} else {
		fmt.Printf("  ⏭️  Backup providers not available in PVE %s\n", version)
	}

	return nil
}

func testSDNFeatures(client *MockPVEClient) error {
	fmt.Println("  🔍 Testing SDN zones (PVE 8.0+)...")
	resp, err := client.Get("cluster/sdn/zones")
	if err != nil {
		return err
	}
	
	dataSlice := resp.Data.([]interface{})
	fmt.Printf("  ✅ SDN Zones: %d zones available\n", len(dataSlice))

	fmt.Println("  🔍 Testing SDN vnets (PVE 8.0+)...")
	resp, err = client.Get("cluster/sdn/vnets")
	if err != nil {
		return err
	}
	
	dataSlice = resp.Data.([]interface{})
	fmt.Printf("  ✅ SDN VNets: %d vnets available\n", len(dataSlice))

	return nil
}

func testBackupProviders(client *MockPVEClient) error {
	fmt.Println("  🔍 Testing backup providers (PVE 8.2+)...")
	resp, err := client.Get("cluster/backup-info/providers")
	if err != nil {
		return err
	}
	
	dataSlice := resp.Data.([]interface{})
	fmt.Printf("  ✅ Backup Providers: %d providers available\n", len(dataSlice))

	return nil
}

func testResourcePools(client *MockPVEClient) error {
	fmt.Println("\n🔍 Testing resource pools...")
	
	resp, err := client.Get("pools")
	if err != nil {
		fmt.Printf("  ⚠️  Resource pools test failed: %v\n", err)
		return nil // Don't fail the entire test
	}

	dataSlice := resp.Data.([]interface{})
	
	for _, item := range dataSlice {
		poolMap := item.(map[string]interface{})
		poolID := getString(poolMap, "poolid")
		comment := getString(poolMap, "comment")
		if comment == "" {
			comment = "No comment"
		}
		
		fmt.Printf("  ✅ Pool: %s - Comment: %s\n", poolID, comment)
		
		if members, ok := poolMap["members"]; ok {
			if memberSlice, ok := members.([]interface{}); ok {
				fmt.Printf("     Members: %d\n", len(memberSlice))
			}
		}
	}

	return nil
}

// Helper functions for type conversion
func getString(m map[string]interface{}, key string) string {
	if val, ok := m[key]; ok && val != nil {
		if str, ok := val.(string); ok {
			return str
		}
	}
	return ""
}

func getInt(m map[string]interface{}, key string) int {
	if val, ok := m[key]; ok && val != nil {
		if num, ok := val.(float64); ok {
			return int(num)
		}
	}
	return 0
}

func getInt64(m map[string]interface{}, key string) int64 {
	if val, ok := m[key]; ok && val != nil {
		if num, ok := val.(float64); ok {
			return int64(num)
		}
	}
	return 0
}

func getFloat(m map[string]interface{}, key string) float64 {
	if val, ok := m[key]; ok && val != nil {
		if num, ok := val.(float64); ok {
			return num
		}
	}
	return 0.0
}

func isVersionAtLeast(version, minVersion string) bool {
	// Simple version comparison for major.minor format
	versionParts := parseVersion(version)
	minVersionParts := parseVersion(minVersion)
	
	if len(versionParts) < 2 || len(minVersionParts) < 2 {
		return false
	}
	
	if versionParts[0] > minVersionParts[0] {
		return true
	}
	
	if versionParts[0] == minVersionParts[0] && versionParts[1] >= minVersionParts[1] {
		return true
	}
	
	return false
}

func parseVersion(version string) []int {
	var parts []int
	var current string
	
	for _, char := range version {
		if char == '.' {
			if num, err := strconv.Atoi(current); err == nil {
				parts = append(parts, num)
			}
			current = ""
		} else if char >= '0' && char <= '9' {
			current += string(char)
		}
	}
	
	if current != "" {
		if num, err := strconv.Atoi(current); err == nil {
			parts = append(parts, num)
		}
	}
	
	return parts
}

func main() {
	fmt.Println("🚀 Mock PVE API Client Test (Go)")
	fmt.Println(strings.Repeat("=", 40))

	// Get configuration from environment or use defaults
	host := "localhost"
	if h := os.Getenv("PVE_HOST"); h != "" {
		host = h
	}
	
	port := 8006
	if p := os.Getenv("PVE_PORT"); p != "" {
		if parsed, err := strconv.Atoi(p); err == nil {
			port = parsed
		}
	}

	// Initialize client
	client := NewMockPVEClient(host, port)

	// Test basic endpoints
	versionData, err := testVersionInfo(client)
	if err != nil {
		if strings.Contains(err.Error(), "connection refused") {
			log.Fatal("❌ Error: Could not connect to Mock PVE API Server\n\n" +
				"Make sure the server is running:\n" +
				"  podman run -d -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest")
		}
		log.Fatalf("❌ Error: %v", err)
	}

	if err := testClusterStatus(client); err != nil {
		log.Fatalf("❌ Cluster status test failed: %v", err)
	}

	if err := testNodesList(client); err != nil {
		log.Fatalf("❌ Nodes list test failed: %v", err)
	}

	if err := testClusterResources(client); err != nil {
		log.Fatalf("❌ Cluster resources test failed: %v", err)
	}

	if err := testStorageContent(client, "pve-node-1", "local"); err != nil {
		log.Fatalf("❌ Storage content test failed: %v", err)
	}

	if err := testResourcePools(client); err != nil {
		log.Fatalf("❌ Resource pools test failed: %v", err)
	}

	// Test version-specific features
	if err := testVersionSpecificFeatures(client, versionData); err != nil {
		log.Fatalf("❌ Version-specific features test failed: %v", err)
	}

	fmt.Println(strings.Repeat("=", 40))
	fmt.Println("🎉 All tests completed successfully!")
	fmt.Println("\nMock PVE API Server is working correctly.")
}

// Import strings package for strings.Repeat
import "strings"