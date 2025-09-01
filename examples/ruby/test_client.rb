#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Example Ruby client for testing Mock PVE API Server.
#
# This script demonstrates how to use the mock server for testing
# Ruby-based PVE client libraries.
#
# Requirements:
#   gem install httparty json
#
# Usage:
#   # Start mock server first
#   podman run -d -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest
#   
#   # Run this script
#   ruby test_client.rb
#

require 'httparty'
require 'json'
require 'uri'

# Simple PVE client for testing against mock server
class MockPVEClient
  include HTTParty
  
  def initialize(host = 'localhost', port = 8006)
    @base_uri = "http://#{host}:#{port}/api2/json"
    self.class.base_uri(@base_uri)
    self.class.default_timeout(10)
  end

  def get(endpoint, options = {})
    response = self.class.get("/#{endpoint.gsub(/^\//, '')}", options)
    handle_response(response)
  end

  def post(endpoint, options = {})
    response = self.class.post("/#{endpoint.gsub(/^\//, '')}", options)
    handle_response(response)
  end

  private

  def handle_response(response)
    if response.success?
      JSON.parse(response.body)
    else
      raise "HTTP #{response.code}: #{response.body}"
    end
  end
end

def test_version_info(client)
  puts '🔍 Testing version information...'
  
  response = client.get('version')
  version_data = response['data']
  
  puts "  ✅ PVE Version: #{version_data['version'] || 'Unknown'}"
  puts "  ✅ Release: #{version_data['release'] || 'Unknown'}"
  puts "  ✅ Repository ID: #{version_data['repoid'] || 'Unknown'}"
  
  version_data
end

def test_cluster_status(client)
  puts "\n🔍 Testing cluster status..."
  
  response = client.get('cluster/status')
  
  response['data'].each do |item|
    case item['type']
    when 'node'
      puts "  ✅ Node: #{item['name']} - Status: #{item['status']}"
    when 'cluster'
      puts "  ✅ Cluster: #{item['name']}"
    end
  end
  
  response['data']
end

def test_nodes_list(client)
  puts "\n🔍 Testing nodes list..."
  
  response = client.get('nodes')
  
  response['data'].each do |node|
    cpu_percent = ((node['cpu'] || 0) * 100).round(1)
    memory_gb = ((node['mem'] || 0) / (1024.0 ** 3)).round(1)
    
    puts "  ✅ Node: #{node['node']} - Status: #{node['status']}"
    puts "     CPU: #{cpu_percent}% - Memory: #{memory_gb}GB"
  end
  
  response['data']
end

def test_cluster_resources(client)
  puts "\n🔍 Testing cluster resources..."
  
  response = client.get('cluster/resources')
  
  resource_counts = Hash.new(0)
  
  response['data'].each do |resource|
    type = resource['type']
    resource_counts[type] += 1
    
    case type
    when 'qemu'
      puts "  ✅ VM #{resource['vmid']}: #{resource['name']} - Status: #{resource['status']}"
    when 'lxc'
      puts "  ✅ CT #{resource['vmid']}: #{resource['name']} - Status: #{resource['status']}"
    when 'storage'
      plugintype = resource['plugintype'] || 'unknown'
      puts "  ✅ Storage: #{resource['storage']} - Type: #{plugintype}"
    end
  end
  
  puts "\n  📊 Resource Summary:"
  resource_counts.each do |type, count|
    puts "     #{type}: #{count}"
  end
  
  response['data']
end

def test_storage_content(client, node = 'pve-node-1', storage = 'local')
  puts "\n🔍 Testing storage content for #{storage} on #{node}..."
  
  begin
    response = client.get("nodes/#{node}/storage/#{storage}/content")
    
    content_types = Hash.new(0)
    
    response['data'].each do |item|
      content_type = item['content']
      content_types[content_type] += 1
      size_gb = ((item['size'] || 0) / (1024.0 ** 3)).round(2)
      
      puts "  ✅ #{item['volid']} - Type: #{content_type} - Size: #{size_gb}GB"
    end
    
    puts "\n  📊 Content Summary:"
    content_types.each do |type, count|
      puts "     #{type}: #{count}"
    end
    
  rescue => e
    puts "  ⚠️  Storage content test failed: #{e.message}"
  end
end

def test_version_specific_features(client, version_data)
  version = version_data['version'] || '8.3'
  puts "\n🔍 Testing version-specific features for PVE #{version}..."
  
  # Test SDN endpoints (available in PVE 8.0+)
  if version_at_least?(version, '8.0')
    test_sdn_features(client)
  else
    puts "  ⏭️  SDN features not available in PVE #{version}"
  end
  
  # Test backup providers (available in PVE 8.2+)
  if version_at_least?(version, '8.2')
    test_backup_providers(client)
  else
    puts "  ⏭️  Backup providers not available in PVE #{version}"
  end
end

def test_sdn_features(client)
  begin
    puts '  🔍 Testing SDN zones (PVE 8.0+)...'
    zones_response = client.get('cluster/sdn/zones')
    puts "  ✅ SDN Zones: #{zones_response['data'].length} zones available"
    
    puts '  🔍 Testing SDN vnets (PVE 8.0+)...'
    vnets_response = client.get('cluster/sdn/vnets')
    puts "  ✅ SDN VNets: #{vnets_response['data'].length} vnets available"
    
  rescue => e
    puts "  ⚠️  SDN endpoints test failed: #{e.message}"
  end
end

def test_backup_providers(client)
  begin
    puts '  🔍 Testing backup providers (PVE 8.2+)...'
    providers_response = client.get('cluster/backup-info/providers')
    puts "  ✅ Backup Providers: #{providers_response['data'].length} providers available"
    
  rescue => e
    puts "  ⚠️  Backup providers test failed: #{e.message}"
  end
end

def test_resource_pools(client)
  puts "\n🔍 Testing resource pools..."
  
  begin
    response = client.get('pools')
    
    response['data'].each do |pool|
      comment = pool['comment'] || 'No comment'
      puts "  ✅ Pool: #{pool['poolid']} - Comment: #{comment}"
      
      if pool['members']
        puts "     Members: #{pool['members'].length}"
      end
    end
    
    response['data']
  rescue => e
    puts "  ⚠️  Resource pools test failed: #{e.message}"
    []
  end
end

def version_at_least?(version, min_version)
  version_parts = parse_version(version)
  min_version_parts = parse_version(min_version)
  
  return false if version_parts.length < 2 || min_version_parts.length < 2
  
  # Compare major version
  return true if version_parts[0] > min_version_parts[0]
  return false if version_parts[0] < min_version_parts[0]
  
  # Major versions equal, compare minor
  version_parts[1] >= min_version_parts[1]
end

def parse_version(version)
  version.scan(/\d+/).map(&:to_i)
end

def main
  puts '🚀 Mock PVE API Client Test (Ruby)'
  puts '=' * 40
  
  # Get configuration from environment or use defaults
  host = ENV['PVE_HOST'] || 'localhost'
  port = (ENV['PVE_PORT'] || '8006').to_i
  
  client = MockPVEClient.new(host, port)
  
  begin
    # Test basic endpoints
    version_data = test_version_info(client)
    test_cluster_status(client)
    test_nodes_list(client)
    test_cluster_resources(client)
    test_storage_content(client)
    test_resource_pools(client)
    
    # Test version-specific features
    test_version_specific_features(client, version_data)
    
    puts "\n#{'=' * 40}"
    puts '🎉 All tests completed successfully!'
    puts "\nMock PVE API Server is working correctly."
    
  rescue => e
    if e.message.include?('Connection refused') || e.message.include?('Failed to open TCP connection')
      puts '❌ Error: Could not connect to Mock PVE API Server'
      puts "\nMake sure the server is running:"
      puts '  podman run -d -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest'
      exit(1)
    else
      puts "❌ Error: #{e.message}"
      puts e.backtrace if ENV['DEBUG']
      exit(1)
    end
  end
end

# Check for required gems
begin
  require 'httparty'
  require 'json'
rescue LoadError => e
  puts '❌ Missing required gems. Please install them with:'
  puts '  gem install httparty json'
  exit(1)
end

# Run the tests
main if __FILE__ == $0