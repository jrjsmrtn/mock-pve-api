# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.Hardware do
  @moduledoc """
  Handler for PVE hardware detection and resource mapping endpoints.
  """

  import Plug.Conn
  alias MockPveApi.State

  # --- Node Hardware Detection ---

  @doc """
  GET /api2/json/nodes/:node/hardware/pci
  Lists PCI devices on node (static mock data).
  """
  def list_pci(conn) do
    pci_devices = [
      %{
        id: "0000:00:00.0",
        class: "0x060000",
        vendor: "0x8086",
        device: "0x1237",
        vendor_name: "Intel Corporation",
        device_name: "440FX - 82441FX PMC",
        iommugroup: 0
      },
      %{
        id: "0000:00:01.0",
        class: "0x060100",
        vendor: "0x8086",
        device: "0x7000",
        vendor_name: "Intel Corporation",
        device_name: "82371SB PIIX3 ISA",
        iommugroup: 1
      },
      %{
        id: "0000:00:02.0",
        class: "0x030000",
        vendor: "0x1234",
        device: "0x1111",
        vendor_name: "QEMU",
        device_name: "QXL paravirtual graphic card",
        iommugroup: 2
      }
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: pci_devices}))
  end

  @doc """
  GET /api2/json/nodes/:node/hardware/pci/:pciid
  Gets PCI device detail (static mock data).
  """
  def get_pci(conn) do
    pciid = conn.path_params["pciid"]

    detail = %{
      id: pciid,
      class: "0x060000",
      vendor: "0x8086",
      device: "0x1237",
      vendor_name: "Intel Corporation",
      device_name: "Mock PCI Device",
      iommugroup: 0,
      mdev: false
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: detail}))
  end

  @doc """
  GET /api2/json/nodes/:node/hardware/usb
  Lists USB devices on node (static mock data).
  """
  def list_usb(conn) do
    usb_devices = [
      %{
        busnum: 1,
        devnum: 1,
        level: 0,
        class: 9,
        vendid: "0x1d6b",
        prodid: "0x0002",
        manufacturer: "Linux Foundation",
        product: "2.0 root hub",
        speed: "480"
      },
      %{
        busnum: 1,
        devnum: 2,
        level: 1,
        class: 0,
        vendid: "0x0627",
        prodid: "0x0001",
        manufacturer: "QEMU",
        product: "QEMU USB Tablet",
        speed: "12"
      }
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: usb_devices}))
  end

  # --- Cluster Resource Mappings: PCI ---

  def list_pci_mappings(conn) do
    mappings = State.list_pci_mappings()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: mappings}))
  end

  def create_pci_mapping(conn) do
    params = conn.body_params
    id = Map.get(params, "id")

    if id do
      case State.create_pci_mapping(id, params) do
        {:ok, mapping} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: mapping}))

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
        Jason.encode!(%{errors: %{id: "property is missing and it is not optional"}})
      )
    end
  end

  def get_pci_mapping(conn) do
    id = conn.path_params["id"]

    case State.get_pci_mapping(id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "PCI mapping '#{id}' not found"}}))

      mapping ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: mapping}))
    end
  end

  def update_pci_mapping(conn) do
    id = conn.path_params["id"]
    params = conn.body_params

    case State.update_pci_mapping(id, params) do
      {:ok, mapping} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: mapping}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  def delete_pci_mapping(conn) do
    id = conn.path_params["id"]

    case State.delete_pci_mapping(id) do
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

  # --- Cluster Resource Mappings: USB ---

  def list_usb_mappings(conn) do
    mappings = State.list_usb_mappings()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: mappings}))
  end

  def create_usb_mapping(conn) do
    params = conn.body_params
    id = Map.get(params, "id")

    if id do
      case State.create_usb_mapping(id, params) do
        {:ok, mapping} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: mapping}))

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
        Jason.encode!(%{errors: %{id: "property is missing and it is not optional"}})
      )
    end
  end

  def get_usb_mapping(conn) do
    id = conn.path_params["id"]

    case State.get_usb_mapping(id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "USB mapping '#{id}' not found"}}))

      mapping ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: mapping}))
    end
  end

  def update_usb_mapping(conn) do
    id = conn.path_params["id"]
    params = conn.body_params

    case State.update_usb_mapping(id, params) do
      {:ok, mapping} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: mapping}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  def delete_usb_mapping(conn) do
    id = conn.path_params["id"]

    case State.delete_usb_mapping(id) do
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

  # --- Cluster Resource Mappings: Dir ---

  def list_dir_mappings(conn) do
    mappings = State.list_dir_mappings()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: mappings}))
  end

  def create_dir_mapping(conn) do
    params = conn.body_params
    id = Map.get(params, "id")

    if id do
      case State.create_dir_mapping(id, params) do
        {:ok, mapping} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: mapping}))

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
        Jason.encode!(%{errors: %{id: "property is missing and it is not optional"}})
      )
    end
  end

  def get_dir_mapping(conn) do
    id = conn.path_params["id"]

    case State.get_dir_mapping(id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "Dir mapping '#{id}' not found"}}))

      mapping ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: mapping}))
    end
  end

  def update_dir_mapping(conn) do
    id = conn.path_params["id"]
    params = conn.body_params

    case State.update_dir_mapping(id, params) do
      {:ok, mapping} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: mapping}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  def delete_dir_mapping(conn) do
    id = conn.path_params["id"]

    case State.delete_dir_mapping(id) do
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
end
