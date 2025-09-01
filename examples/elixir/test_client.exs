#!/usr/bin/env elixir

# Example Elixir client for testing Mock PVE API Server.
#
# This script demonstrates how to use the mock server for testing
# Elixir-based PVE client libraries.
#
# Requirements:
#   mix deps.get
#
# Usage:
#   # Start mock server first
#   podman run -d -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest
#   
#   # Run this script
#   elixir test_client.exs

defmodule MockPVEClient do
  @moduledoc """
  Simple PVE client for testing against mock server.
  """

  @base_url "http://localhost:8006/api2/json"

  def get(endpoint, params \\ []) do
    url = build_url(endpoint, params)
    
    case HTTPoison.get(url, [], timeout: 10_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}
      
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        {:error, {status, body}}
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  def post(endpoint, data \\ %{}) do
    url = build_url(endpoint)
    body = Jason.encode!(data)
    headers = [{"Content-Type", "application/json"}]
    
    case HTTPoison.post(url, body, headers, timeout: 10_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        {:ok, Jason.decode!(response_body)}
      
      {:ok, %HTTPoison.Response{status_code: status, body: response_body}} ->
        {:error, {status, response_body}}
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_url(endpoint, params \\ []) do
    endpoint = String.trim_leading(endpoint, "/")
    base = "#{@base_url}/#{endpoint}"
    
    case params do
      [] -> base
      params -> "#{base}?#{URI.encode_query(params)}"
    end
  end
end

defmodule TestRunner do
  @moduledoc """
  Test runner for Mock PVE API Server.
  """

  def run do
    IO.puts("🚀 Mock PVE API Client Test (Elixir)")
    IO.puts(String.duplicate("=", 40))
    
    try do
      version_data = test_version_info()
      test_cluster_status()
      test_nodes_list()
      test_cluster_resources()
      test_storage_content()
      test_resource_pools()
      test_version_specific_features(version_data)
      
      IO.puts("\n" <> String.duplicate("=", 40))
      IO.puts("🎉 All tests completed successfully!")
      IO.puts("\nMock PVE API Server is working correctly.")
      
    rescue
      error ->
        case error do
          %HTTPoison.Error{reason: :econnrefused} ->
            IO.puts("❌ Error: Could not connect to Mock PVE API Server")
            IO.puts("\nMake sure the server is running:")
            IO.puts("  podman run -d -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest")
            System.halt(1)
          
          _ ->
            IO.puts("❌ Unexpected error: #{inspect(error)}")
            System.halt(1)
        end
    end
  end

  defp test_version_info do
    IO.puts("🔍 Testing version information...")
    
    {:ok, response} = MockPVEClient.get("version")
    version_data = response["data"]
    
    IO.puts("  ✅ PVE Version: #{version_data["version"] || "Unknown"}")
    IO.puts("  ✅ Release: #{version_data["release"] || "Unknown"}")
    IO.puts("  ✅ Repository ID: #{version_data["repoid"] || "Unknown"}")
    
    version_data
  end

  defp test_cluster_status do
    IO.puts("\n🔍 Testing cluster status...")
    
    {:ok, response} = MockPVEClient.get("cluster/status")
    
    Enum.each(response["data"], fn item ->
      case item["type"] do
        "node" ->
          IO.puts("  ✅ Node: #{item["name"]} - Status: #{item["status"]}")
        
        "cluster" ->
          IO.puts("  ✅ Cluster: #{item["name"]}")
        
        _ ->
          :ok
      end
    end)
    
    response["data"]
  end

  defp test_nodes_list do
    IO.puts("\n🔍 Testing nodes list...")
    
    {:ok, response} = MockPVEClient.get("nodes")
    
    Enum.each(response["data"], fn node ->
      cpu_percent = (node["cpu"] || 0) * 100 |> Float.round(1)
      memory_gb = (node["mem"] || 0) / :math.pow(1024, 3) |> Float.round(1)
      
      IO.puts("  ✅ Node: #{node["node"]} - Status: #{node["status"]}")
      IO.puts("     CPU: #{cpu_percent}% - Memory: #{memory_gb}GB")
    end)
    
    response["data"]
  end

  defp test_cluster_resources do
    IO.puts("\n🔍 Testing cluster resources...")
    
    {:ok, response} = MockPVEClient.get("cluster/resources")
    
    resource_counts = 
      response["data"]
      |> Enum.reduce(%{}, fn resource, acc ->
        type = resource["type"]
        Map.put(acc, type, Map.get(acc, type, 0) + 1)
      end)
    
    Enum.each(response["data"], fn resource ->
      case resource["type"] do
        "qemu" ->
          IO.puts("  ✅ VM #{resource["vmid"]}: #{resource["name"]} - Status: #{resource["status"]}")
        
        "lxc" ->
          IO.puts("  ✅ CT #{resource["vmid"]}: #{resource["name"]} - Status: #{resource["status"]}")
        
        "storage" ->
          plugintype = resource["plugintype"] || "unknown"
          IO.puts("  ✅ Storage: #{resource["storage"]} - Type: #{plugintype}")
        
        _ ->
          :ok
      end
    end)
    
    IO.puts("\n  📊 Resource Summary:")
    Enum.each(resource_counts, fn {type, count} ->
      IO.puts("     #{type}: #{count}")
    end)
    
    response["data"]
  end

  defp test_storage_content(node \\ "pve-node-1", storage \\ "local") do
    IO.puts("\n🔍 Testing storage content for #{storage} on #{node}...")
    
    case MockPVEClient.get("nodes/#{node}/storage/#{storage}/content") do
      {:ok, response} ->
        content_types = 
          response["data"]
          |> Enum.reduce(%{}, fn item, acc ->
            type = item["content"]
            Map.put(acc, type, Map.get(acc, type, 0) + 1)
          end)
        
        Enum.each(response["data"], fn item ->
          size_gb = (item["size"] || 0) / :math.pow(1024, 3) |> Float.round(2)
          IO.puts("  ✅ #{item["volid"]} - Type: #{item["content"]} - Size: #{size_gb}GB")
        end)
        
        IO.puts("\n  📊 Content Summary:")
        Enum.each(content_types, fn {type, count} ->
          IO.puts("     #{type}: #{count}")
        end)
      
      {:error, reason} ->
        IO.puts("  ⚠️  Storage content test failed: #{inspect(reason)}")
    end
  end

  defp test_resource_pools do
    IO.puts("\n🔍 Testing resource pools...")
    
    case MockPVEClient.get("pools") do
      {:ok, response} ->
        Enum.each(response["data"], fn pool ->
          comment = pool["comment"] || "No comment"
          IO.puts("  ✅ Pool: #{pool["poolid"]} - Comment: #{comment}")
          
          if pool["members"] do
            IO.puts("     Members: #{length(pool["members"])}")
          end
        end)
        
        response["data"]
      
      {:error, reason} ->
        IO.puts("  ⚠️  Resource pools test failed: #{inspect(reason)}")
        []
    end
  end

  defp test_version_specific_features(version_data) do
    version = version_data["version"] || "8.3"
    IO.puts("\n🔍 Testing version-specific features for PVE #{version}...")
    
    # Test SDN endpoints (available in PVE 8.0+)
    if Version.compare(version, "8.0") != :lt do
      test_sdn_features()
    else
      IO.puts("  ⏭️  SDN features not available in PVE #{version}")
    end
    
    # Test backup providers (available in PVE 8.2+)
    if Version.compare(version, "8.2") != :lt do
      test_backup_providers()
    else
      IO.puts("  ⏭️  Backup providers not available in PVE #{version}")
    end
  end

  defp test_sdn_features do
    try do
      IO.puts("  🔍 Testing SDN zones (PVE 8.0+)...")
      {:ok, zones_response} = MockPVEClient.get("cluster/sdn/zones")
      IO.puts("  ✅ SDN Zones: #{length(zones_response["data"])} zones available")
      
      IO.puts("  🔍 Testing SDN vnets (PVE 8.0+)...")
      {:ok, vnets_response} = MockPVEClient.get("cluster/sdn/vnets")
      IO.puts("  ✅ SDN VNets: #{length(vnets_response["data"])} vnets available")
      
    rescue
      error ->
        IO.puts("  ⚠️  SDN endpoints test failed: #{inspect(error)}")
    end
  end

  defp test_backup_providers do
    try do
      IO.puts("  🔍 Testing backup providers (PVE 8.2+)...")
      {:ok, providers_response} = MockPVEClient.get("cluster/backup-info/providers")
      IO.puts("  ✅ Backup Providers: #{length(providers_response["data"])} providers available")
      
    rescue
      error ->
        IO.puts("  ⚠️  Backup providers test failed: #{inspect(error)}")
    end
  end
end

# Check if required dependencies are available
dependencies = [:httpoison, :jason]

missing_deps = Enum.filter(dependencies, fn dep ->
  try do
    dep.__info__(:module)
    false
  rescue
    _ -> true
  end
end)

if length(missing_deps) > 0 do
  IO.puts("❌ Missing dependencies: #{Enum.join(missing_deps, ", ")}")
  IO.puts("Please install them with: mix deps.get")
  System.halt(1)
else
  # All dependencies available, run tests
  TestRunner.run()
end