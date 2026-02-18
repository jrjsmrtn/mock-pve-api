# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Docs.Coverage do
  @moduledoc """
  Generates comprehensive API reference documentation from the Coverage module.

  This task reads endpoint definitions from `MockPveApi.Coverage` and generates
  a single consolidated API reference at `docs/reference/api-reference.md`.

  ## Usage

      mix docs.coverage           # Generate the API reference documentation
      mix docs.coverage --check   # Check if docs are up-to-date (for CI)

  ## Options

    * `--check` - Instead of writing, verify that existing docs match generated content.
                  Exits with status 1 if docs are outdated. Useful for CI/pre-commit hooks.

  """

  use Mix.Task

  @shortdoc "Generate API reference documentation from Coverage module"

  @output_path "docs/reference/api-reference.md"

  @impl Mix.Task
  def run(args) do
    # Start the application to ensure modules are loaded
    Mix.Task.run("compile", [])

    check_only = "--check" in args

    generated_content = generate_markdown()

    if check_only do
      check_docs_current(generated_content)
    else
      write_docs(generated_content)
    end
  end

  defp check_docs_current(generated_content) do
    case File.read(@output_path) do
      {:ok, existing_content} ->
        if existing_content == generated_content do
          Mix.shell().info("✓ API reference documentation is up-to-date")
          :ok
        else
          Mix.shell().error("""
          ✗ API reference documentation is outdated!

          Run 'mix docs.coverage' to regenerate, then commit the changes.
          """)

          exit({:shutdown, 1})
        end

      {:error, :enoent} ->
        Mix.shell().error("""
        ✗ API reference documentation not found at #{@output_path}

        Run 'mix docs.coverage' to generate it.
        """)

        exit({:shutdown, 1})
    end
  end

  defp write_docs(content) do
    # Ensure directory exists
    @output_path |> Path.dirname() |> File.mkdir_p!()

    File.write!(@output_path, content)
    Mix.shell().info("✓ Generated #{@output_path}")
  end

  defp generate_markdown do
    stats = MockPveApi.Coverage.get_coverage_stats()
    category_stats = MockPveApi.Coverage.get_category_stats()

    categories =
      MockPveApi.Coverage.category_modules()
      |> Enum.map(& &1.category())

    [
      generate_header(),
      generate_quick_start(),
      generate_overview(stats, category_stats),
      generate_status_legend(),
      Enum.map(categories, &generate_category_section/1),
      generate_error_responses(),
      generate_configuration(),
      generate_compatibility_notes(),
      generate_footer()
    ]
    |> List.flatten()
    |> Enum.join("\n")
  end

  defp generate_header do
    """
    # Mock PVE API Reference

    Complete reference for all supported endpoints in the Mock PVE API Server.
    This document is the single source of truth for API documentation, automatically
    generated from the `MockPveApi.Coverage` module.

    > **Note**: This document is auto-generated. Do not edit manually.
    > Run `mix docs.coverage` to regenerate after modifying endpoint definitions.

    ## Base Information

    | Property | Value |
    |----------|-------|
    | **Base URL** | `http://localhost:8006/api2/json` |
    | **HTTPS URL** | `https://localhost:8006/api2/json` (when SSL enabled) |
    | **Authentication** | Optional (mock server accepts all requests) |
    | **Content Type** | `application/json` |
    | **Supported PVE Versions** | 7.0, 7.1, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3, 9.0 |

    """
  end

  defp generate_quick_start do
    """
    ## Quick Start

    ```bash
    # Start the mock server
    podman run -d -p 8006:8006 -e MOCK_PVE_VERSION=8.3 ghcr.io/jrjsmrtn/mock-pve-api:latest

    # Test the connection
    curl http://localhost:8006/api2/json/version

    # List nodes
    curl http://localhost:8006/api2/json/nodes

    # List VMs on a node
    curl http://localhost:8006/api2/json/nodes/pve-node-1/qemu
    ```

    ---

    """
  end

  defp generate_overview(stats, category_stats) do
    category_rows =
      category_stats
      |> Enum.sort_by(fn {cat, _} -> category_order(cat) end)
      |> Enum.map(fn {category, cat_stats} ->
        "| #{format_category_name(category)} | #{cat_stats.total} | #{cat_stats.implemented} | #{cat_stats.coverage_percentage}% |"
      end)
      |> Enum.join("\n")

    """
    ## Coverage Overview

    The mock-pve-api server provides comprehensive coverage of the Proxmox VE API
    with systematic tracking across all supported versions (7.0 - 9.0).

    | Category | Total | Implemented | Coverage |
    |----------|-------|-------------|----------|
    #{category_rows}
    | **TOTAL** | **#{stats.total}** | **#{stats.implemented}** | **#{stats.coverage_percentage}%** |

    """
  end

  defp generate_status_legend do
    """
    ## Status Legend

    | Icon | Status | Description |
    |------|--------|-------------|
    | ✅ | Implemented | Fully functional with complete response simulation |
    | 📋 | Planned | Cataloged but not yet implemented |
    | 🔴 | PVE 8.0+ | Feature requires PVE 8.0 or later |
    | 🟠 | PVE 9.0+ | Feature requires PVE 9.0 or later |

    ## Priority Levels

    - **Critical**: Essential endpoints for basic client functionality
    - **High**: Important endpoints for common operations
    - **Medium**: Useful endpoints for advanced features
    - **Low**: Optional endpoints for specialized use cases

    ---

    """
  end

  defp generate_category_section(category) do
    endpoints = MockPveApi.Coverage.get_category_endpoints(category)

    if Enum.empty?(endpoints) do
      []
    else
      endpoint_docs =
        endpoints
        |> Enum.sort_by(& &1.path)
        |> Enum.map(&generate_endpoint_doc/1)
        |> Enum.join("\n")

      """
      ## #{format_category_title(category)}

      #{endpoint_docs}
      ---

      """
    end
  end

  defp generate_endpoint_doc(endpoint) do
    status_icon = status_to_icon(endpoint.status)
    version_badge = version_badge(endpoint)
    methods = endpoint.methods |> Enum.map(&String.upcase(to_string(&1))) |> Enum.join(", ")

    params_section = generate_params_section(endpoint.parameters)
    example_section = generate_example_section(endpoint)
    notes_section = if endpoint.notes, do: "\n**Notes**: #{endpoint.notes}\n", else: ""

    """
    ### `#{short_path(endpoint.path)}` #{status_icon}#{version_badge}

    #{endpoint.description}

    | Property | Value |
    |----------|-------|
    | **Methods** | #{methods} |
    | **Priority** | #{format_priority(endpoint.priority)} |
    | **Since** | PVE #{endpoint.since} |
    #{params_section}#{example_section}#{notes_section}
    """
  end

  defp short_path(path) do
    String.replace(path, "/api2/json", "")
  end

  defp generate_params_section([]), do: ""

  defp generate_params_section(params) do
    param_rows =
      params
      |> Enum.map(fn p ->
        req = if p.required, do: "Yes", else: "No"
        values = if p.values, do: "`#{Enum.join(p.values, "`, `")}`", else: "-"
        "| `#{p.name}` | #{p.type} | #{req} | #{p.description} | #{values} |"
      end)
      |> Enum.join("\n")

    """

    **Parameters**:

    | Name | Type | Required | Description | Values |
    |------|------|----------|-------------|--------|
    #{param_rows}
    """
  end

  defp generate_example_section(endpoint) do
    # Check if endpoint has explicit example_response
    example =
      if Map.has_key?(endpoint, :example_response) && endpoint.example_response do
        endpoint.example_response
      else
        generate_example_for_endpoint(endpoint)
      end

    if example do
      json = Jason.encode!(example, pretty: true)

      """

      **Example Response**:
      ```json
      #{json}
      ```
      """
    else
      ""
    end
  end

  defp generate_example_for_endpoint(endpoint) do
    # Generate realistic examples based on endpoint path and schema
    path = endpoint.path

    cond do
      path == "/api2/json/version" ->
        %{data: %{version: "8.3", release: "8.3-1", repoid: "abcd1234", keyboard: "en-us"}}

      path == "/api2/json/cluster/status" ->
        %{
          data: [
            %{type: "cluster", name: "mock-cluster", nodes: 3, quorate: 1},
            %{type: "node", id: "node/pve-node-1", name: "pve-node-1", status: "online"}
          ]
        }

      path == "/api2/json/cluster/resources" ->
        %{
          data: [
            %{
              id: "node/pve-node-1",
              type: "node",
              node: "pve-node-1",
              status: "online",
              cpu: 0.15,
              maxcpu: 8,
              mem: 2_147_483_648,
              maxmem: 8_589_934_592
            },
            %{
              id: "qemu/100",
              type: "qemu",
              vmid: 100,
              name: "test-vm",
              node: "pve-node-1",
              status: "running"
            }
          ]
        }

      path == "/api2/json/nodes" ->
        %{
          data: [
            %{
              node: "pve-node-1",
              status: "online",
              cpu: 0.15,
              maxcpu: 8,
              mem: 2_147_483_648,
              maxmem: 8_589_934_592,
              uptime: 86400
            }
          ]
        }

      String.contains?(path, "/qemu") && !String.contains?(path, "{vmid}") ->
        %{
          data: [
            %{
              vmid: 100,
              name: "test-vm",
              status: "running",
              cpu: 0.25,
              maxcpu: 2,
              mem: 1_073_741_824,
              maxmem: 2_147_483_648
            }
          ]
        }

      String.contains?(path, "/qemu/{vmid}/status/{command}") ->
        %{data: "UPID:pve-node-1:00012345:00000000:qmstart:100:user@pam:"}

      String.contains?(path, "/qemu/{vmid}/clone") ->
        %{data: "UPID:pve-node-1:00012346:00000000:qmclone:100:user@pam:"}

      String.contains?(path, "/qemu/{vmid}") ->
        %{
          data: %{
            vmid: 100,
            name: "test-vm",
            status: "running",
            cpu: 0.25,
            cpus: 2,
            mem: 1_073_741_824,
            maxmem: 2_147_483_648,
            uptime: 3600
          }
        }

      String.contains?(path, "/lxc") && !String.contains?(path, "{vmid}") ->
        %{
          data: [
            %{
              vmid: 200,
              name: "test-container",
              status: "running",
              cpu: 0.10,
              maxcpu: 1,
              mem: 536_870_912,
              maxmem: 1_073_741_824
            }
          ]
        }

      String.contains?(path, "/lxc/{vmid}/clone") ->
        %{data: "UPID:pve-node-1:00012347:00000000:vzclone:200:user@pam:"}

      String.contains?(path, "/lxc/{vmid}") ->
        %{
          data: %{
            vmid: 200,
            name: "test-container",
            status: "running",
            cpu: 0.10,
            cpus: 1,
            mem: 536_870_912,
            maxmem: 1_073_741_824
          }
        }

      String.contains?(path, "/storage/{storage}/content") ->
        %{
          data: [
            %{
              volid: "local:iso/debian-12.iso",
              content: "iso",
              format: "iso",
              size: 658_505_728
            }
          ]
        }

      String.contains?(path, "/storage/{storage}/status") ->
        %{
          data: %{
            storage: "local",
            type: "dir",
            active: 1,
            used: 21_474_836_480,
            total: 107_374_182_400
          }
        }

      String.contains?(path, "/storage") ->
        %{
          data: [
            %{
              storage: "local",
              type: "dir",
              active: 1,
              enabled: 1,
              used: 21_474_836_480,
              total: 107_374_182_400
            }
          ]
        }

      path == "/api2/json/cluster/sdn/zones" ->
        %{data: [%{zone: "localnetwork", type: "simple", nodes: "pve-node-1,pve-node-2"}]}

      String.contains?(path, "/sdn/zones/{zone}") ->
        %{data: %{zone: "localnetwork", type: "simple", nodes: "pve-node-1,pve-node-2"}}

      path == "/api2/json/cluster/sdn/vnets" ->
        %{data: [%{vnet: "vnet100", zone: "localnetwork", tag: 100}]}

      path == "/api2/json/cluster/backup-info/providers" ->
        %{data: [%{provider: "pbs", name: "Proxmox Backup Server", enabled: 1}]}

      path == "/api2/json/cluster/ha/affinity" ->
        %{data: [%{name: "affinity-rule-1", nodes: "pve-node-1,pve-node-2", type: "group"}]}

      path == "/api2/json/pools" ->
        %{data: [%{poolid: "production", comment: "Production environment"}]}

      String.contains?(path, "/pools/{poolid}") ->
        %{
          data: %{
            poolid: "production",
            comment: "Production environment",
            members: [%{type: "qemu", vmid: 100, node: "pve-node-1"}]
          }
        }

      path == "/api2/json/access/users" ->
        %{
          data: [
            %{userid: "root@pam", comment: "Built-in Superuser", enable: 1},
            %{userid: "testuser@pve", email: "test@example.com", enable: 1}
          ]
        }

      String.contains?(path, "/access/users/{userid}/token") ->
        %{data: %{tokenid: "automation", privsep: 1, expire: 0, comment: "Automation token"}}

      String.contains?(path, "/access/users/{userid}") ->
        %{
          data: %{
            userid: "testuser@pve",
            email: "test@example.com",
            enable: 1,
            groups: ["developers"]
          }
        }

      path == "/api2/json/access/groups" ->
        %{data: [%{groupid: "developers", comment: "Development team"}]}

      String.contains?(path, "/access/groups/{groupid}") ->
        %{data: %{groupid: "developers", comment: "Development team", members: ["testuser@pve"]}}

      path == "/api2/json/access/ticket" ->
        %{data: %{ticket: "PVE:root@pam:12345678::...", CSRFPreventionToken: "12345678:..."}}

      path == "/api2/json/access/domains" ->
        %{data: [%{realm: "pam", type: "pam", comment: "Linux PAM standard authentication"}]}

      String.contains?(path, "/time") ->
        %{data: %{timezone: "UTC", localtime: 1_702_828_800, time: "2024-12-17T12:00:00Z"}}

      String.contains?(path, "/cluster/config/nodes") && !String.contains?(path, "{node}") ->
        %{data: [%{name: "pve-node-1", nodeid: 1, votes: 1}]}

      String.contains?(path, "/cluster/config/nodes/{node}") ->
        %{data: nil}

      path == "/api2/json/cluster/config" ->
        %{data: %{cluster_name: "mock-cluster", version: 1}}

      path == "/api2/json/cluster/config/join" ->
        %{data: "UPID:pve-node-1:00012348:00000000:clusterjoin::user@pam:"}

      true ->
        # Default based on response schema
        case endpoint.response_schema do
          %{data: :array} -> %{data: []}
          %{data: :object} -> %{data: %{}}
          %{data: :string} -> %{data: "OK"}
          _ -> nil
        end
    end
  end

  defp generate_error_responses do
    """
    ## Error Responses

    ### Standard Error Format

    All errors return JSON with the following structure:

    ```json
    {
      "errors": ["Error message describing what went wrong"]
    }
    ```

    ### HTTP Status Codes

    | Code | Description |
    |------|-------------|
    | **200** | Request successful |
    | **400** | Invalid parameters or request |
    | **404** | Resource or endpoint not found |
    | **501** | Feature not available in configured PVE version |
    | **500** | Server error |

    ### Version-Specific Errors

    When requesting features not available in the configured PVE version:

    ```json
    {
      "errors": [
        "Feature not implemented",
        "SDN features require PVE 8.0+, currently simulating 7.4"
      ]
    }
    ```

    ---

    """
  end

  defp generate_configuration do
    """
    ## Configuration

    ### Environment Variables

    | Variable | Default | Description |
    |----------|---------|-------------|
    | `MOCK_PVE_VERSION` | `8.3` | PVE version to simulate (7.0-9.0) |
    | `MOCK_PVE_PORT` | `8006` | Server port |
    | `MOCK_PVE_HOST` | `0.0.0.0` | Bind address |
    | `MOCK_PVE_SSL_ENABLED` | `false` | Enable HTTPS |
    | `MOCK_PVE_SSL_KEYFILE` | - | Path to SSL private key |
    | `MOCK_PVE_SSL_CERTFILE` | - | Path to SSL certificate |
    | `MOCK_PVE_LOG_LEVEL` | `info` | Logging level |
    | `MOCK_PVE_DELAY` | `0` | Response delay in milliseconds |
    | `MOCK_PVE_ERROR_RATE` | `0` | Error injection rate (0-100) |

    ### Multi-Version Testing

    ```bash
    # Run multiple versions simultaneously
    for version in 7.4 8.0 8.3 9.0; do
      docker run -d --name pve-$version \\
        -p $((8000 + ${version%%.*})):8006 \\
        -e MOCK_PVE_VERSION=$version \\
        ghcr.io/jrjsmrtn/mock-pve-api:latest
    done
    ```

    ---

    """
  end

  defp generate_compatibility_notes do
    """
    ## Compatibility Notes

    ### Differences from Real PVE API

    1. **Authentication**: Mock server accepts all requests without authentication
    2. **State Persistence**: State is lost when container restarts
    3. **Real Operations**: Operations return immediately (no actual VMs created)
    4. **Resource Limits**: Simulated resources have configurable limits

    ### Compatibility Features

    1. **Response Schemas**: Match real PVE API response formats
    2. **HTTP Status Codes**: Correct status codes for different scenarios
    3. **Version-Specific Features**: Accurate feature availability per version
    4. **Error Messages**: Similar error message formats

    ### Client Library Usage

    Configure your PVE client library to use `http://localhost:8006` as the PVE host
    with SSL verification disabled. The mock server accepts all authentication requests.

    ---

    """
  end

  defp generate_footer do
    """
    *This API reference is automatically generated from the `MockPveApi.Coverage` module.*
    *Run `mix docs.coverage` to regenerate after modifying endpoint definitions.*
    """
  end

  # Helper functions

  defp status_to_icon(:implemented), do: "✅"
  defp status_to_icon(:partial), do: "🟡"
  defp status_to_icon(:in_progress), do: "🔄"
  defp status_to_icon(:planned), do: "📋"
  defp status_to_icon(:not_supported), do: "❌"
  defp status_to_icon(:pve8_only), do: "✅ 🔴"
  defp status_to_icon(:pve9_only), do: "✅ 🟠"
  defp status_to_icon(_), do: ""

  defp version_badge(%{since: since}) when since >= "9.0", do: " 🟠"
  defp version_badge(%{since: since}) when since >= "8.0", do: " 🔴"
  defp version_badge(_), do: ""

  defp format_category_name(:version), do: "Version"
  defp format_category_name(:cluster), do: "Cluster"
  defp format_category_name(:nodes), do: "Nodes"
  defp format_category_name(:vms), do: "Virtual Machines"
  defp format_category_name(:containers), do: "LXC Containers"
  defp format_category_name(:storage), do: "Storage"
  defp format_category_name(:access), do: "Access Control"
  defp format_category_name(:pools), do: "Resource Pools"
  defp format_category_name(:sdn), do: "SDN"
  defp format_category_name(:monitoring), do: "Monitoring"
  defp format_category_name(:backup), do: "Backup"
  defp format_category_name(:hardware), do: "Hardware"
  defp format_category_name(:firewall), do: "Firewall"
  defp format_category_name(other), do: other |> to_string() |> String.capitalize()

  defp format_category_title(:version), do: "Version Information"
  defp format_category_title(:cluster), do: "Cluster Management"
  defp format_category_title(:nodes), do: "Node Management"
  defp format_category_title(:vms), do: "Virtual Machine Management"
  defp format_category_title(:containers), do: "LXC Container Management"
  defp format_category_title(:storage), do: "Storage Management"
  defp format_category_title(:access), do: "Access Control & User Management"
  defp format_category_title(:pools), do: "Resource Pool Management"
  defp format_category_title(:sdn), do: "Software-Defined Networking (SDN)"
  defp format_category_title(:monitoring), do: "Monitoring & Metrics"
  defp format_category_title(:backup), do: "Backup & Restore"
  defp format_category_title(:hardware), do: "Hardware Detection & Passthrough"
  defp format_category_title(:firewall), do: "Firewall Management"
  defp format_category_title(other), do: other |> to_string() |> String.capitalize()

  defp format_priority(:critical), do: "Critical"
  defp format_priority(:high), do: "High"
  defp format_priority(:medium), do: "Medium"
  defp format_priority(:low), do: "Low"
  defp format_priority(other), do: to_string(other)

  defp category_order(:version), do: 0
  defp category_order(:cluster), do: 1
  defp category_order(:nodes), do: 2
  defp category_order(:vms), do: 3
  defp category_order(:containers), do: 4
  defp category_order(:storage), do: 5
  defp category_order(:access), do: 6
  defp category_order(:pools), do: 7
  defp category_order(:sdn), do: 8
  defp category_order(:monitoring), do: 9
  defp category_order(:backup), do: 10
  defp category_order(:hardware), do: 11
  defp category_order(:firewall), do: 12
  defp category_order(_), do: 99
end
