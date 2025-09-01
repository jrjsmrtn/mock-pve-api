defmodule MockPveApi.Handlers.Access do
  @moduledoc """
  Handler for PVE access/authentication endpoints.
  """

  import Plug.Conn
  require Logger

  @doc """
  POST /api2/json/access/ticket
  Creates authentication ticket for username/password authentication.
  """
  def create_ticket(conn) do
    params = conn.body_params

    username = Map.get(params, "username")
    password = Map.get(params, "password")

    # For mock purposes, accept any username/password combination
    # In real PVE, this would validate against PAM, LDAP, etc.
    if username && password do
      ticket_data = %{
        username: username,
        ticket: "PVE:#{username}:mock-ticket-#{:rand.uniform(999_999)}",
        CSRFPreventionToken: "mock-csrf-token-#{:rand.uniform(999_999)}"
      }

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{data: ticket_data}))
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{
          errors: %{
            username: "property is missing and it is not optional",
            password: "property is missing and it is not optional"
          }
        })
      )
    end
  end
end
