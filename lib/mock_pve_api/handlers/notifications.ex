# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.Notifications do
  @moduledoc """
  Handler for PVE notification-related endpoints (PVE 8.1+).

  Supports gotify, sendmail endpoint types and notification matchers.
  """

  import Plug.Conn
  alias MockPveApi.State

  # Gotify endpoints

  @doc "GET /api2/json/cluster/notifications/endpoints/gotify"
  def list_gotify(conn) do
    endpoints = State.list_notification_endpoints(:gotify)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: endpoints}))
  end

  @doc "POST /api2/json/cluster/notifications/endpoints/gotify"
  def create_gotify(conn) do
    params = conn.body_params
    name = Map.get(params, "name")

    if is_nil(name) or name == "" do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{name: "property is missing and it is not optional"}})
      )
    else
      atom_params =
        params
        |> Enum.reduce(%{}, fn
          {"name", _}, acc -> acc
          {k, v}, acc -> Map.put(acc, String.to_atom(k), v)
        end)

      case State.create_notification_endpoint(:gotify, name, atom_params) do
        {:ok, _endpoint} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: nil}))

        {:error, :already_exists} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            400,
            Jason.encode!(%{errors: %{name: "Endpoint '#{name}' already exists"}})
          )
      end
    end
  end

  @doc "GET /api2/json/cluster/notifications/endpoints/gotify/:name"
  def get_gotify(conn) do
    name = conn.path_params["name"]

    case State.get_notification_endpoint(:gotify, name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "Endpoint '#{name}' not found"}}))

      endpoint ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: endpoint}))
    end
  end

  @doc "PUT /api2/json/cluster/notifications/endpoints/gotify/:name"
  def update_gotify(conn) do
    name = conn.path_params["name"]
    params = conn.body_params

    atom_params =
      params
      |> Enum.reduce(%{}, fn
        {"name", _}, acc -> acc
        {k, v}, acc -> Map.put(acc, String.to_atom(k), v)
      end)

    case State.update_notification_endpoint(:gotify, name, atom_params) do
      {:ok, _endpoint} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc "DELETE /api2/json/cluster/notifications/endpoints/gotify/:name"
  def delete_gotify(conn) do
    name = conn.path_params["name"]

    case State.delete_notification_endpoint(:gotify, name) do
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

  # Sendmail endpoints

  @doc "GET /api2/json/cluster/notifications/endpoints/sendmail"
  def list_sendmail(conn) do
    endpoints = State.list_notification_endpoints(:sendmail)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: endpoints}))
  end

  @doc "POST /api2/json/cluster/notifications/endpoints/sendmail"
  def create_sendmail(conn) do
    params = conn.body_params
    name = Map.get(params, "name")

    if is_nil(name) or name == "" do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{name: "property is missing and it is not optional"}})
      )
    else
      atom_params =
        params
        |> Enum.reduce(%{}, fn
          {"name", _}, acc -> acc
          {k, v}, acc -> Map.put(acc, String.to_atom(k), v)
        end)

      case State.create_notification_endpoint(:sendmail, name, atom_params) do
        {:ok, _endpoint} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: nil}))

        {:error, :already_exists} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            400,
            Jason.encode!(%{errors: %{name: "Endpoint '#{name}' already exists"}})
          )
      end
    end
  end

  @doc "GET /api2/json/cluster/notifications/endpoints/sendmail/:name"
  def get_sendmail(conn) do
    name = conn.path_params["name"]

    case State.get_notification_endpoint(:sendmail, name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "Endpoint '#{name}' not found"}}))

      endpoint ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: endpoint}))
    end
  end

  @doc "PUT /api2/json/cluster/notifications/endpoints/sendmail/:name"
  def update_sendmail(conn) do
    name = conn.path_params["name"]
    params = conn.body_params

    atom_params =
      params
      |> Enum.reduce(%{}, fn
        {"name", _}, acc -> acc
        {k, v}, acc -> Map.put(acc, String.to_atom(k), v)
      end)

    case State.update_notification_endpoint(:sendmail, name, atom_params) do
      {:ok, _endpoint} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc "DELETE /api2/json/cluster/notifications/endpoints/sendmail/:name"
  def delete_sendmail(conn) do
    name = conn.path_params["name"]

    case State.delete_notification_endpoint(:sendmail, name) do
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

  # Matcher endpoints

  @doc "GET /api2/json/cluster/notifications/matchers"
  def list_matchers(conn) do
    matchers = State.list_notification_matchers()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: matchers}))
  end

  @doc "POST /api2/json/cluster/notifications/matchers"
  def create_matcher(conn) do
    params = conn.body_params
    name = Map.get(params, "name")

    if is_nil(name) or name == "" do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{name: "property is missing and it is not optional"}})
      )
    else
      atom_params =
        params
        |> Enum.reduce(%{}, fn
          {"name", _}, acc -> acc
          {k, v}, acc -> Map.put(acc, String.to_atom(k), v)
        end)

      case State.create_notification_matcher(name, atom_params) do
        {:ok, _matcher} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: nil}))

        {:error, :already_exists} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{name: "Matcher '#{name}' already exists"}}))
      end
    end
  end

  @doc "GET /api2/json/cluster/notifications/matchers/:name"
  def get_matcher(conn) do
    name = conn.path_params["name"]

    case State.get_notification_matcher(name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "Matcher '#{name}' not found"}}))

      matcher ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: matcher}))
    end
  end

  @doc "PUT /api2/json/cluster/notifications/matchers/:name"
  def update_matcher(conn) do
    name = conn.path_params["name"]
    params = conn.body_params

    atom_params =
      params
      |> Enum.reduce(%{}, fn
        {"name", _}, acc -> acc
        {k, v}, acc -> Map.put(acc, String.to_atom(k), v)
      end)

    case State.update_notification_matcher(name, atom_params) do
      {:ok, _matcher} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc "DELETE /api2/json/cluster/notifications/matchers/:name"
  def delete_matcher(conn) do
    name = conn.path_params["name"]

    case State.delete_notification_matcher(name) do
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
