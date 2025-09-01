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

  alias MockPveApi.{State, Capabilities}

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json, :urlencoded], json_decoder: Jason)
  plug(:authenticate)
  plug(:check_endpoint_support)
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

  get "/api2/json/access/users/:userid" do
    Access.get_user(conn)
  end

  post "/api2/json/access/users/:userid/token/:tokenid" do
    Access.create_api_token(conn)
  end

  get "/api2/json/access/users/:userid/token" do
    Access.list_user_tokens(conn)
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
  get "/api2/json/cluster/resources" do
    Cluster.get_resources(conn)
  end

  get "/api2/json/cluster/nextid" do
    Cluster.get_next_vmid(conn)
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

  # Catch all for unimplemented endpoints
  match _ do
    Logger.warning("Unimplemented endpoint: #{conn.method} #{conn.request_path}")

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      501,
      Jason.encode!(%{
        "errors" => %{
          "message" =>
            "Endpoint not implemented in mock server: #{conn.method} #{conn.request_path}"
        }
      })
    )
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
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, :token, token}
      ["PVEAuthCookie=" <> ticket] -> {:ok, :ticket, ticket}
      ["PVEAPIToken=" <> token] -> {:ok, :api_token, token}
      [] -> {:error, :missing}
      _ -> {:error, :missing}
    end
  end

  defp add_cors_headers(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "authorization, content-type")
  end
end
