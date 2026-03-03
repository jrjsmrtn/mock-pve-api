# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.Storage do
  @moduledoc """
  Handler for PVE storage-related endpoints.
  """

  import Plug.Conn
  require Logger
  alias MockPveApi.State

  @doc """
  GET /api2/json/storage
  Lists all storage definitions.
  """
  def list_storage(conn) do
    storage = State.get_storage()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: storage}))
  end

  @doc """
  GET /api2/json/nodes/:node/storage/:storage/content
  Gets storage content for a specific storage on a node.
  """
  def get_storage_content(conn) do
    node_name = conn.path_params["node"]
    storage_id = conn.path_params["storage"]

    case State.get_node(node_name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{
            errors: %{message: "Node '#{node_name}' not found"}
          })
        )

      _node ->
        content = State.get_storage_content(node_name, storage_id)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: content}))
    end
  end

  @doc """
  POST /api2/json/nodes/:node/storage/:storage/content
  Uploads or creates storage content (ISOs, templates, backups).
  """
  def create_storage_content(conn) do
    node_name = conn.path_params["node"]
    storage_id = conn.path_params["storage"]
    params = conn.body_params

    case State.get_node(node_name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{
            errors: %{message: "Node '#{node_name}' not found"}
          })
        )

      _node ->
        content_type = Map.get(params, "content", "backup")
        filename = Map.get(params, "filename", "uploaded-content")

        # Simulate content creation
        new_content = %{
          content: content_type,
          ctime: :os.system_time(:second),
          format: get_format_from_filename(filename),
          notes: Map.get(params, "notes", ""),
          # 1GB default
          size: Map.get(params, "size", 1_073_741_824),
          storage: storage_id,
          volid: "#{storage_id}:#{content_type}/#{filename}"
        }

        case State.add_storage_content(node_name, storage_id, new_content) do
          {:ok, created_content} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: created_content}))

          {:error, message} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
        end
    end
  end

  @doc """
  GET /api2/json/nodes/:node/storage/:storage/status
  Gets storage status (capacity) for a specific storage on a node.
  """
  def get_storage_status(conn) do
    node_name = conn.path_params["node"]
    storage_id = conn.path_params["storage"]

    case State.get_node(node_name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{
            errors: %{message: "Node '#{node_name}' not found"}
          })
        )

      _node ->
        case State.get_storage_status(storage_id) do
          nil ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              404,
              Jason.encode!(%{
                errors: %{message: "Storage '#{storage_id}' not found"}
              })
            )

          status ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: status}))
        end
    end
  end

  @doc """
  POST /api2/json/storage
  Creates a new storage definition.
  """
  def create_storage(conn) do
    params = conn.body_params
    storage_id = Map.get(params, "storage")

    if storage_id do
      case State.create_storage(storage_id, params) do
        {:ok, storage} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: storage}))

        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{storage: "property is missing and it is not optional"}})
      )
    end
  end

  @doc """
  GET /api2/json/storage/:storage
  Gets a specific storage definition.
  """
  def get_storage(conn) do
    storage_id = conn.path_params["storage"]

    case State.get_storage_by_id(storage_id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{errors: %{message: "Storage '#{storage_id}' not found"}})
        )

      storage ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: storage}))
    end
  end

  @doc """
  PUT /api2/json/storage/:storage
  Updates a storage definition.
  """
  def update_storage(conn) do
    storage_id = conn.path_params["storage"]
    params = conn.body_params

    case State.update_storage(storage_id, params) do
      {:ok, storage} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: storage}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  DELETE /api2/json/storage/:storage
  Deletes a storage definition.
  """
  def delete_storage(conn) do
    storage_id = conn.path_params["storage"]

    case State.delete_storage(storage_id) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/storage/:storage/content/:volume
  Gets specific storage volume information.
  """
  def get_storage_volume(conn) do
    storage_id = conn.path_params["storage"]
    volume = conn.path_params["volume"]
    node_name = conn.path_params["node"]

    case State.get_storage_volume(node_name, storage_id, volume) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{errors: %{message: "Volume '#{volume}' not found"}})
        )

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))

      volume_info ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: volume_info}))
    end
  end

  @doc """
  DELETE /api2/json/nodes/:node/storage/:storage/content/:volume
  Deletes a storage volume.
  """
  def delete_storage_volume(conn) do
    storage_id = conn.path_params["storage"]
    volume = conn.path_params["volume"]
    node_name = conn.path_params["node"]

    case State.delete_storage_volume(node_name, storage_id, volume) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  POST /api2/json/nodes/:node/storage/:storage/upload
  Uploads content to storage. Returns a task UPID.
  """
  def upload_storage_content(conn) do
    node_name = conn.path_params["node"]
    storage_id = conn.path_params["storage"]
    _params = conn.body_params

    case State.get_node(node_name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{errors: %{message: "Node '#{node_name}' not found"}})
        )

      _node ->
        upid = "UPID:#{node_name}:00000001:00000000:00000000:upload:#{storage_id}:root@pam:"

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: upid}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/storage/:storage/file-restore/list
  Lists files in a backup for single-file restore.
  """
  def list_file_restore(conn) do
    data = [
      %{filepath: "/", type: "d", text: "/", leaf: 0},
      %{filepath: "/etc", type: "d", text: "etc", leaf: 0},
      %{filepath: "/var", type: "d", text: "var", leaf: 0}
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  @doc """
  GET /api2/json/nodes/:node/storage/:storage/file-restore/download
  Downloads files from a backup for single-file restore.
  """
  def download_file_restore(conn) do
    conn
    |> put_resp_content_type("application/octet-stream")
    |> send_resp(200, "mock-file-content")
  end

  @doc """
  GET /api2/json/nodes/:node/storage/:storage/prunebackups
  Get prune information for backups.
  """
  def list_prunebackups(conn) do
    data = [
      %{
        volid: "local:backup/vzdump-qemu-100-2024_01_01-00_00_00.vma.zst",
        ctime: 1_704_067_200,
        mark: "keep",
        type: "qemu"
      }
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  @doc """
  DELETE /api2/json/nodes/:node/storage/:storage/prunebackups
  Prune old backups. Returns a task UPID.
  """
  def delete_prunebackups(conn) do
    node_name = conn.path_params["node"]
    storage_id = conn.path_params["storage"]
    upid = "UPID:#{node_name}:00000001:00000000:00000000:prunebackups:#{storage_id}:root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  # Helper function to determine format from filename
  defp get_format_from_filename(filename) do
    case Path.extname(filename) do
      ".iso" -> "iso"
      ".img" -> "raw"
      ".qcow2" -> "qcow2"
      ".vmdk" -> "vmdk"
      ".vma" -> "vma"
      ".tar.gz" -> "tar+gzip"
      ".tar.lzo" -> "tar+lzo"
      _ -> "raw"
    end
  end
end
