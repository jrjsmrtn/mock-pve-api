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
          size: Map.get(params, "size", 1073741824),  # 1GB default
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
