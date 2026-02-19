# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.Snapshots do
  @moduledoc """
  Handler for VM and container snapshot endpoints.

  Implements CRUD operations for snapshots on both QEMU VMs and LXC containers:
  - List snapshots
  - Create snapshot
  - Get snapshot info
  - Delete snapshot
  - Get/update snapshot configuration
  - Rollback to snapshot
  """

  import Plug.Conn

  alias MockPveApi.State

  @doc """
  GET /api2/json/nodes/:node/qemu/:vmid/snapshot
  GET /api2/json/nodes/:node/lxc/:vmid/snapshot
  Lists all snapshots for a VM or container.
  """
  def list_snapshots(conn) do
    node_name = conn.path_params["node"]
    vmid = parse_vmid(conn.path_params["vmid"])
    type = resource_type(conn.request_path)

    case get_resource(type, node_name, vmid) do
      nil ->
        send_not_found(conn, type, vmid)

      _resource ->
        snapshots = State.list_snapshots(vmid)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: snapshots}))
    end
  end

  @doc """
  POST /api2/json/nodes/:node/qemu/:vmid/snapshot
  POST /api2/json/nodes/:node/lxc/:vmid/snapshot
  Creates a new snapshot.
  """
  def create_snapshot(conn) do
    node_name = conn.path_params["node"]
    vmid = parse_vmid(conn.path_params["vmid"])
    type = resource_type(conn.request_path)
    params = conn.body_params
    snapname = Map.get(params, "snapname", "snap-#{System.system_time(:second)}")

    case get_resource(type, node_name, vmid) do
      nil ->
        send_not_found(conn, type, vmid)

      _resource ->
        case State.create_snapshot(vmid, snapname, params) do
          {:ok, _snapshot} ->
            task_type = if type == :vm, do: "qmsnapshot", else: "pctsnapshot"

            {:ok, upid} =
              State.create_task(node_name, task_type, %{vmid: vmid, snapname: snapname})

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: upid}))

          {:error, message} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
        end
    end
  end

  @doc """
  GET /api2/json/nodes/:node/qemu/:vmid/snapshot/:snapname
  GET /api2/json/nodes/:node/lxc/:vmid/snapshot/:snapname
  Gets snapshot information.
  """
  def get_snapshot(conn) do
    node_name = conn.path_params["node"]
    vmid = parse_vmid(conn.path_params["vmid"])
    snapname = conn.path_params["snapname"]
    type = resource_type(conn.request_path)

    case get_resource(type, node_name, vmid) do
      nil ->
        send_not_found(conn, type, vmid)

      _resource ->
        case State.get_snapshot(vmid, snapname) do
          nil ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              404,
              Jason.encode!(%{errors: %{message: "Snapshot '#{snapname}' not found"}})
            )

          snapshot ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: snapshot}))
        end
    end
  end

  @doc """
  DELETE /api2/json/nodes/:node/qemu/:vmid/snapshot/:snapname
  DELETE /api2/json/nodes/:node/lxc/:vmid/snapshot/:snapname
  Deletes a snapshot.
  """
  def delete_snapshot(conn) do
    node_name = conn.path_params["node"]
    vmid = parse_vmid(conn.path_params["vmid"])
    snapname = conn.path_params["snapname"]
    type = resource_type(conn.request_path)

    case get_resource(type, node_name, vmid) do
      nil ->
        send_not_found(conn, type, vmid)

      _resource ->
        case State.delete_snapshot(vmid, snapname) do
          :ok ->
            task_type = if type == :vm, do: "qmdelsnapshot", else: "pctdelsnapshot"

            {:ok, upid} =
              State.create_task(node_name, task_type, %{vmid: vmid, snapname: snapname})

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: upid}))

          {:error, message} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
        end
    end
  end

  @doc """
  GET /api2/json/nodes/:node/qemu/:vmid/snapshot/:snapname/config
  GET /api2/json/nodes/:node/lxc/:vmid/snapshot/:snapname/config
  Gets snapshot configuration.
  """
  def get_snapshot_config(conn) do
    node_name = conn.path_params["node"]
    vmid = parse_vmid(conn.path_params["vmid"])
    snapname = conn.path_params["snapname"]
    type = resource_type(conn.request_path)

    case get_resource(type, node_name, vmid) do
      nil ->
        send_not_found(conn, type, vmid)

      _resource ->
        case State.get_snapshot_config(vmid, snapname) do
          {:ok, config} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: config}))

          {:error, message} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
        end
    end
  end

  @doc """
  PUT /api2/json/nodes/:node/qemu/:vmid/snapshot/:snapname/config
  PUT /api2/json/nodes/:node/lxc/:vmid/snapshot/:snapname/config
  Updates snapshot configuration (description).
  """
  def update_snapshot_config(conn) do
    node_name = conn.path_params["node"]
    vmid = parse_vmid(conn.path_params["vmid"])
    snapname = conn.path_params["snapname"]
    type = resource_type(conn.request_path)
    params = conn.body_params

    case get_resource(type, node_name, vmid) do
      nil ->
        send_not_found(conn, type, vmid)

      _resource ->
        case State.update_snapshot_config(vmid, snapname, params) do
          {:ok, _updated} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: nil}))

          {:error, message} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
        end
    end
  end

  @doc """
  POST /api2/json/nodes/:node/qemu/:vmid/snapshot/:snapname/rollback
  POST /api2/json/nodes/:node/lxc/:vmid/snapshot/:snapname/rollback
  Rolls back to a snapshot.
  """
  def rollback_snapshot(conn) do
    node_name = conn.path_params["node"]
    vmid = parse_vmid(conn.path_params["vmid"])
    snapname = conn.path_params["snapname"]
    type = resource_type(conn.request_path)

    case get_resource(type, node_name, vmid) do
      nil ->
        send_not_found(conn, type, vmid)

      _resource ->
        case State.rollback_snapshot(vmid, snapname) do
          :ok ->
            task_type = if type == :vm, do: "qmrollback", else: "pctrollback"

            {:ok, upid} =
              State.create_task(node_name, task_type, %{vmid: vmid, snapname: snapname})

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: upid}))

          {:error, message} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
        end
    end
  end

  # Private helpers

  defp parse_vmid(vmid) when is_binary(vmid), do: String.to_integer(vmid)
  defp parse_vmid(vmid) when is_integer(vmid), do: vmid

  defp resource_type(path) do
    cond do
      String.contains?(path, "/qemu/") -> :vm
      String.contains?(path, "/lxc/") -> :container
    end
  end

  defp get_resource(:vm, node, vmid), do: State.get_vm(node, vmid)
  defp get_resource(:container, node, vmid), do: State.get_container(node, vmid)

  defp send_not_found(conn, :vm, vmid) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{errors: %{message: "VM #{vmid} not found"}}))
  end

  defp send_not_found(conn, :container, vmid) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{errors: %{message: "Container #{vmid} not found"}}))
  end
end
