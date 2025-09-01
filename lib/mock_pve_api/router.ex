defmodule MockPveApi.Router do
  @moduledoc """
  HTTP router for the Mock PVE Server.

  Routes incoming requests to appropriate handlers and manages authentication,
  API versioning, and response formatting to match real PVE API behavior.
  """

  use Plug.Router
  require Logger

  alias MockPveApi.Handlers.{
    Version,
    Access,
    Nodes,
    Cluster,
    Pools,
    Storage,
    Metrics
  }

  alias MockPveApi.{State, Capabilities, Coverage}

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json, :urlencoded], json_decoder: Jason)
  plug(:authenticate)
  plug(:check_coverage_status)
  plug(:check_endpoint_support)
  plug(:track_endpoint_usage)
  plug(:add_cors_headers)
  plug(:dispatch)

  # Version endpoint (unauthenticated)
  get "/api2/json/version" do
    Version.get_version(conn)
  end

  # Access endpoints
  post "/api2/json/access/ticket" do
    Access.create_ticket(conn)
  end

  get "/api2/json/access/users" do
    Access.list_users(conn)
  end

  post "/api2/json/access/users" do
    Access.create_user(conn)
  end

  get "/api2/json/access/users/:userid" do
    Access.get_user(conn)
  end

  put "/api2/json/access/users/:userid" do
    Access.update_user(conn)
  end

  delete "/api2/json/access/users/:userid" do
    Access.delete_user(conn)
  end

  get "/api2/json/access/users/:userid/token" do
    Access.list_user_tokens(conn)
  end

  post "/api2/json/access/users/:userid/token/:tokenid" do
    Access.create_api_token(conn)
  end

  get "/api2/json/access/users/:userid/token/:tokenid" do
    Access.get_api_token(conn)
  end

  put "/api2/json/access/users/:userid/token/:tokenid" do
    Access.update_api_token(conn)
  end

  delete "/api2/json/access/users/:userid/token/:tokenid" do
    Access.delete_api_token(conn)
  end

  get "/api2/json/access/groups" do
    Access.list_groups(conn)
  end

  post "/api2/json/access/groups" do
    Access.create_group(conn)
  end

  get "/api2/json/access/groups/:groupid" do
    Access.get_group(conn)
  end

  put "/api2/json/access/groups/:groupid" do
    Access.update_group(conn)
  end

  delete "/api2/json/access/groups/:groupid" do
    Access.delete_group(conn)
  end

  get "/api2/json/access/domains" do
    Access.list_domains(conn)
  end

  get "/api2/json/access/permissions" do
    Access.get_permissions(conn)
  end

  put "/api2/json/access/acl" do
    Access.set_acl(conn)
  end

  get "/api2/json/access/roles" do
    Access.list_roles(conn)
  end

  # Node endpoints
  get "/api2/json/nodes" do
    Nodes.list_nodes(conn)
  end

  get "/api2/json/nodes/:node" do
    Nodes.get_node(conn)
  end

  get "/api2/json/nodes/:node/status" do
    Nodes.get_node_status(conn)
  end

  get "/api2/json/nodes/:node/version" do
    Nodes.get_node_version(conn)
  end

  get "/api2/json/nodes/:node/tasks" do
    Nodes.get_node_tasks(conn)
  end

  get "/api2/json/nodes/:node/syslog" do
    Nodes.get_node_syslog(conn)
  end

  get "/api2/json/nodes/:node/network" do
    Nodes.get_node_network(conn)
  end

  post "/api2/json/nodes/:node/execute" do
    Nodes.execute_command(conn)
  end

  # VM endpoints
  get "/api2/json/nodes/:node/qemu" do
    Nodes.list_vms(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/config" do
    Nodes.get_vm_config(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/status/current" do
    Nodes.get_vm_status(conn)
  end

  post "/api2/json/nodes/:node/qemu" do
    Nodes.create_vm(conn)
  end

  put "/api2/json/nodes/:node/qemu/:vmid/config" do
    Nodes.update_vm_config(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/status/:action" do
    Nodes.vm_action(conn)
  end

  delete "/api2/json/nodes/:node/qemu/:vmid" do
    Nodes.delete_vm(conn)
  end

  # Container endpoints
  get "/api2/json/nodes/:node/lxc" do
    Nodes.list_containers(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/config" do
    Nodes.get_container_config(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/status/current" do
    Nodes.get_container_status(conn)
  end

  post "/api2/json/nodes/:node/lxc" do
    Nodes.create_container(conn)
  end

  put "/api2/json/nodes/:node/lxc/:vmid/config" do
    Nodes.update_container_config(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/status/:action" do
    Nodes.container_action(conn)
  end

  delete "/api2/json/nodes/:node/lxc/:vmid" do
    Nodes.delete_container(conn)
  end

  # VM/Container migration, backup and snapshot endpoints
  post "/api2/json/nodes/:node/qemu/:vmid/migrate" do
    Nodes.migrate_vm(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/migrate" do
    Nodes.migrate_container(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/snapshot" do
    Nodes.create_vm_snapshot(conn)
  end

  post "/api2/json/nodes/:node/qemu/:vmid/clone" do
    Nodes.clone_vm(conn)
  end

  post "/api2/json/nodes/:node/lxc/:vmid/clone" do
    Nodes.clone_container(conn)
  end

  post "/api2/json/nodes/:node/vzdump" do
    Nodes.create_backup(conn)
  end

  get "/api2/json/nodes/:node/storage/:storage/backup" do
    Nodes.list_backup_files(conn)
  end

  # Task endpoints with progress
  get "/api2/json/nodes/:node/tasks/:upid/status" do
    Nodes.get_task_status(conn)
  end

  get "/api2/json/nodes/:node/tasks/:upid/log" do
    Nodes.get_task_log(conn)
  end

  # Metrics and statistics endpoints
  get "/api2/json/nodes/:node/rrd" do
    Metrics.get_node_rrd(conn)
  end

  get "/api2/json/nodes/:node/rrddata" do
    Metrics.get_node_rrd_data(conn)
  end

  get "/api2/json/nodes/:node/qemu/:vmid/rrd" do
    Metrics.get_vm_rrd(conn)
  end

  get "/api2/json/nodes/:node/lxc/:vmid/rrd" do
    Metrics.get_container_rrd(conn)
  end

  get "/api2/json/nodes/:node/netstat" do
    Metrics.get_node_netstat(conn)
  end

  get "/api2/json/nodes/:node/report" do
    Metrics.get_node_report(conn)
  end

  get "/api2/json/cluster/metrics/server/:id" do
    Metrics.get_cluster_metrics(conn)
  end

  # Storage endpoints
  get "/api2/json/storage" do
    Storage.list_storage(conn)
  end

  get "/api2/json/nodes/:node/storage/:storage/content" do
    Storage.get_storage_content(conn)
  end

  # Cluster endpoints  
  get "/api2/json/cluster/status" do
    Cluster.get_cluster_status(conn)
  end

  get "/api2/json/cluster/resources" do
    Cluster.get_resources(conn)
  end

  get "/api2/json/cluster/nextid" do
    Cluster.get_next_vmid(conn)
  end

  get "/api2/json/cluster/config" do
    Cluster.get_cluster_config(conn)
  end

  put "/api2/json/cluster/config" do
    Cluster.update_cluster_config(conn)
  end

  post "/api2/json/cluster/config/join" do
    Cluster.join_cluster(conn)
  end

  get "/api2/json/cluster/config/nodes" do
    Cluster.get_cluster_nodes_config(conn)
  end

  delete "/api2/json/cluster/config/nodes/:node" do
    Cluster.remove_cluster_node(conn)
  end

  # Pool endpoints
  get "/api2/json/pools" do
    Pools.list_pools(conn)
  end

  get "/api2/json/pools/:poolid" do
    Pools.get_pool(conn)
  end

  post "/api2/json/pools" do
    Pools.create_pool(conn)
  end

  put "/api2/json/pools/:poolid" do
    Pools.update_pool(conn)
  end

  delete "/api2/json/pools/:poolid" do
    Pools.delete_pool(conn)
  end

  # SDN endpoints (PVE 8.0+ only)
  get "/api2/json/cluster/sdn/zones" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  get "/api2/json/cluster/sdn/vnets" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  get "/api2/json/cluster/sdn/subnets" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  # Realm sync endpoints (PVE 8.0+ only)
  post "/api2/json/access/domains/:realm/sync" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: "sync-task-upid"}))
  end

  # Notification endpoints (PVE 8.1+ only)
  get "/api2/json/cluster/notifications/endpoints" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  get "/api2/json/cluster/notifications/filters" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  # VMware import endpoints (PVE 8.2+ only)
  post "/api2/json/nodes/:node/storage/:storage/import" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: "import-task-upid"}))
  end

  # Backup provider endpoints (PVE 8.2+ only)
  get "/api2/json/cluster/backup-providers" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  # Coverage API endpoints
  get "/api2/json/_coverage/stats" do
    stats = Coverage.get_coverage_stats()
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: stats}))
  end

  get "/api2/json/_coverage/categories" do
    category_stats = Coverage.get_category_stats()
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: category_stats}))
  end

  get "/api2/json/_coverage/missing" do
    missing = Coverage.get_missing_critical_endpoints()
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: missing}))
  end

  # Catch all for unimplemented endpoints
  match _ do
    endpoint_path = conn.request_path
    method = String.downcase(conn.method) |> String.to_atom()
    
    case Coverage.get_endpoint_info(endpoint_path) do
      nil ->
        Logger.warning("Unknown endpoint: #{conn.method} #{endpoint_path}")
        send_unknown_endpoint_error(conn, endpoint_path)
        
      endpoint_info ->
        case endpoint_info.status do
          :not_supported ->
            Logger.info("Endpoint not supported: #{endpoint_path}")
            send_not_supported_error(conn, endpoint_info)
            
          :planned ->
            Logger.info("Endpoint planned but not implemented: #{endpoint_path}")
            send_planned_error(conn, endpoint_info)
            
          :pve8_only ->
            version = State.get_pve_version()
            if version_gte?(version, "8.0") do
              send_not_implemented_error(conn, endpoint_info)
            else
              send_version_error(conn, endpoint_info, "8.0")
            end
            
          :pve9_only ->
            version = State.get_pve_version()
            if version_gte?(version, "9.0") do
              send_not_implemented_error(conn, endpoint_info)
            else
              send_version_error(conn, endpoint_info, "9.0")
            end
            
          _ ->
            if method in endpoint_info.methods do
              Logger.warning("Endpoint matched but handler missing: #{endpoint_path}")
              send_handler_missing_error(conn, endpoint_info)
            else
              Logger.warning("Method not allowed: #{conn.method} #{endpoint_path}")
              send_method_not_allowed_error(conn, endpoint_info)
            end
        end
    end
  end

  # Endpoint support checking plug
  defp check_endpoint_support(%Plug.Conn{request_path: "/api2/json/version"} = conn, _opts) do
    # Version endpoint is always supported
    conn
  end

  defp check_endpoint_support(conn, _opts) do
    if State.endpoint_supported?(conn.request_path) do
      conn
    else
      Logger.warning("Endpoint not supported in current PVE version: #{conn.request_path}")

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        501,
        Jason.encode!(%{
          "errors" => %{
            "message" =>
              "Feature not available in PVE version #{State.get_pve_version()}: #{conn.request_path}"
          }
        })
      )
      |> halt()
    end
  end

  # Authentication plug
  defp authenticate(%Plug.Conn{request_path: "/api2/json/version"} = conn, _opts) do
    # Version endpoint doesn't require authentication
    conn
  end

  defp authenticate(%Plug.Conn{request_path: "/api2/json/access/ticket"} = conn, _opts) do
    # Ticket creation endpoint doesn't require authentication
    conn
  end

  defp authenticate(conn, _opts) do
    case get_auth_header(conn) do
      {:ok, _auth_type, _token} ->
        # In a real implementation, we'd validate the token/ticket
        # For mocking purposes, we just check that auth is present
        conn

      {:error, :missing} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          401,
          Jason.encode!(%{
            "errors" => %{
              "message" => "authentication failure"
            }
          })
        )
        |> halt()
    end
  end

  defp get_auth_header(conn) do
    # Check Authorization header first
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, :token, token}
      ["PVEAuthCookie=" <> ticket] -> {:ok, :ticket, ticket}
      ["PVEAPIToken=" <> token] -> {:ok, :api_token, token}
      [] ->
        # Check cookies if no Authorization header
        case get_req_header(conn, "cookie") do
          [cookie_header] ->
            # Parse cookies to find PVEAuthCookie
            case parse_cookies(cookie_header) do
              %{"PVEAuthCookie" => ticket} -> {:ok, :ticket, ticket}
              _ -> {:error, :missing}
            end
          [] -> {:error, :missing}
        end
      _ -> {:error, :missing}
    end
  end

  defp parse_cookies(cookie_header) do
    cookie_header
    |> String.split(";")
    |> Enum.map(&String.trim/1)
    |> Enum.reduce(%{}, fn cookie, acc ->
      case String.split(cookie, "=", parts: 2) do
        [key, value] -> Map.put(acc, String.trim(key), String.trim(value))
        _ -> acc
      end
    end)
  end

  # Coverage status checking plug
  defp check_coverage_status(%Plug.Conn{request_path: "/api2/json/version"} = conn, _opts) do
    # Version endpoint always passes
    conn
  end

  defp check_coverage_status(%Plug.Conn{request_path: "/api2/json/_coverage" <> _} = conn, _opts) do
    # Coverage API endpoints always pass
    conn
  end

  defp check_coverage_status(conn, _opts) do
    endpoint_path = conn.request_path
    method = String.downcase(conn.method) |> String.to_atom()
    
    case Coverage.get_endpoint_info(endpoint_path) do
      nil ->
        # Unknown endpoint, let catch-all handle it
        conn
        
      endpoint_info ->
        case {endpoint_info.status, method in endpoint_info.methods} do
          {:not_supported, _} ->
            send_not_supported_error(conn, endpoint_info) |> halt()
            
          {:pve8_only, _} ->
            version = State.get_pve_version()
            if version_gte?(version, "8.0") do
              conn
            else
              send_version_error(conn, endpoint_info, "8.0") |> halt()
            end
            
          {:pve9_only, _} ->
            version = State.get_pve_version()
            if version_gte?(version, "9.0") do
              conn
            else
              send_version_error(conn, endpoint_info, "9.0") |> halt()
            end
            
          {_, false} ->
            send_method_not_allowed_error(conn, endpoint_info) |> halt()
            
          _ ->
            conn
        end
    end
  end

  # Endpoint usage tracking plug
  defp track_endpoint_usage(%Plug.Conn{request_path: "/api2/json/_coverage" <> _} = conn, _opts) do
    # Don't track coverage API calls
    conn
  end

  defp track_endpoint_usage(conn, _opts) do
    # Track endpoint usage for metrics
    endpoint_path = conn.request_path
    method = String.downcase(conn.method) |> String.to_atom()
    
    case Coverage.get_endpoint_info(endpoint_path) do
      nil -> conn
      endpoint_info ->
        Logger.debug("API call: #{method} #{endpoint_path} (status: #{endpoint_info.status})")
        # TODO: Add metrics collection here
        conn
    end
  end

  # Error response helpers
  defp send_unknown_endpoint_error(conn, endpoint_path) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{
      errors: ["Unknown endpoint: #{endpoint_path}"],
      coverage_info: "Endpoint not found in coverage matrix"
    }))
  end

  defp send_not_supported_error(conn, endpoint_info) do
    conn
    |> put_resp_content_type("application/json") 
    |> send_resp(501, Jason.encode!(%{
      errors: ["Endpoint not supported: #{endpoint_info.path}"],
      coverage_info: %{
        status: endpoint_info.status,
        description: endpoint_info.description,
        notes: endpoint_info.notes
      }
    }))
  end

  defp send_planned_error(conn, endpoint_info) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(501, Jason.encode!(%{
      errors: ["Endpoint planned but not yet implemented: #{endpoint_info.path}"],
      coverage_info: %{
        status: endpoint_info.status,
        priority: endpoint_info.priority,
        description: endpoint_info.description,
        notes: endpoint_info.notes
      }
    }))
  end

  defp send_version_error(conn, endpoint_info, required_version) do
    current_version = State.get_pve_version()
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(501, Jason.encode!(%{
      errors: [
        "Feature not available in PVE #{current_version}",
        "Endpoint #{endpoint_info.path} requires PVE #{required_version}+"
      ],
      coverage_info: %{
        required_version: required_version,
        current_version: current_version,
        capabilities_required: endpoint_info.capabilities_required
      }
    }))
  end

  defp send_not_implemented_error(conn, endpoint_info) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(501, Jason.encode!(%{
      errors: ["Endpoint found but handler not implemented: #{endpoint_info.path}"],
      coverage_info: %{
        status: endpoint_info.status,
        handler_module: endpoint_info.handler_module,
        notes: endpoint_info.notes
      }
    }))
  end

  defp send_handler_missing_error(conn, endpoint_info) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(500, Jason.encode!(%{
      errors: ["Handler module missing for implemented endpoint: #{endpoint_info.path}"],
      coverage_info: %{
        expected_handler: endpoint_info.handler_module,
        status: endpoint_info.status
      }
    }))
  end

  defp send_method_not_allowed_error(conn, endpoint_info) do
    conn
    |> put_resp_content_type("application/json") 
    |> put_resp_header("allow", Enum.join(endpoint_info.methods, ", ") |> String.upcase())
    |> send_resp(405, Jason.encode!(%{
      errors: ["Method not allowed: #{String.upcase(conn.method)}"],
      coverage_info: %{
        allowed_methods: endpoint_info.methods,
        endpoint: endpoint_info.path
      }
    }))
  end

  defp version_gte?(version_a, version_b) do
    # Simple version comparison - could be enhanced
    String.to_float(version_a) >= String.to_float(version_b)
  rescue
    _ -> true
  end

  defp add_cors_headers(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "authorization, content-type")
  end
end
