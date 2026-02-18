# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage do
  @moduledoc """
  PVE API coverage matrix for the Mock PVE Server.

  This module aggregates endpoint definitions from category-based sub-modules
  under `MockPveApi.Coverage.*`. Each sub-module implements the
  `MockPveApi.Coverage.Category` behaviour and owns a slice of the PVE API
  surface area.

  The canonical reference for PVE API endpoints is the
  [PVE API Viewer](https://pve.proxmox.com/pve-docs/api-viewer/).

  Status Legend:
  - :implemented - Fully implemented with complete functionality
  - :partial - Core functionality available, some features missing
  - :in_progress - Currently being developed
  - :planned - Planned for implementation
  - :not_supported - Not supported/not planned
  - :pve8_only - Available in PVE 8.x+ only
  - :pve9_only - Available in PVE 9.x+ only
  """

  @type endpoint_category() ::
          :version
          | :cluster
          | :nodes
          | :vms
          | :containers
          | :storage
          | :access
          | :pools
          | :sdn
          | :monitoring
          | :backup
          | :hardware
          | :firewall

  @type http_method() :: :get | :post | :put | :delete | :patch

  @type implementation_status() ::
          :implemented
          | :partial
          | :in_progress
          | :planned
          | :not_supported
          | :pve8_only
          | :pve9_only

  @type priority() :: :critical | :high | :medium | :low

  @type parameter() :: %{
          name: String.t(),
          type: :string | :integer | :boolean | :array | :object,
          required: boolean(),
          description: String.t(),
          values: [String.t()] | nil,
          default: any() | nil
        }

  @type endpoint_info() :: %{
          path: String.t(),
          methods: [http_method()],
          status: implementation_status(),
          priority: priority(),
          since: String.t(),
          description: String.t(),
          parameters: [parameter()],
          response_schema: map(),
          example_response: map() | nil,
          capabilities_required: [atom()],
          test_coverage: boolean(),
          handler_module: atom() | nil,
          notes: String.t() | nil
        }

  # Category sub-modules — order determines display order in docs
  @category_modules [
    MockPveApi.Coverage.Version,
    MockPveApi.Coverage.Cluster,
    MockPveApi.Coverage.Nodes,
    MockPveApi.Coverage.VMs,
    MockPveApi.Coverage.Containers,
    MockPveApi.Coverage.Storage,
    MockPveApi.Coverage.Access,
    MockPveApi.Coverage.Pools,
    MockPveApi.Coverage.Sdn,
    MockPveApi.Coverage.Monitoring,
    MockPveApi.Coverage.Backup,
    MockPveApi.Coverage.Hardware,
    MockPveApi.Coverage.Firewall
  ]

  # Build the coverage matrix at compile time from sub-modules.
  # Inject the map key as `path` for any endpoint where `path` is empty
  # (planned endpoints use a compact helper that omits the path).
  @coverage_matrix Enum.into(@category_modules, %{}, fn mod ->
                     endpoints =
                       mod.endpoints()
                       |> Enum.into(%{}, fn {key, info} ->
                         if info.path == "" do
                           {key, %{info | path: key}}
                         else
                           {key, info}
                         end
                       end)

                     {mod.category(), endpoints}
                   end)

  @doc """
  Gets endpoint information by path pattern matching.

  ## Examples

      iex> info = MockPveApi.Coverage.get_endpoint_info("/api2/json/version")
      iex> info.path
      "/api2/json/version"
      iex> info.status
      :implemented

      iex> info = MockPveApi.Coverage.get_endpoint_info("/api2/json/nodes/pve1/qemu/100")
      iex> info.path
      "/api2/json/nodes/{node}/qemu/{vmid}"
  """
  @spec get_endpoint_info(String.t()) :: endpoint_info() | nil
  def get_endpoint_info(endpoint_path) do
    @coverage_matrix
    |> Enum.flat_map(fn {_category, endpoints} -> Map.to_list(endpoints) end)
    |> Enum.find_value(fn {pattern, info} ->
      if matches_pattern?(endpoint_path, pattern), do: info
    end)
  end

  @doc """
  Gets all endpoints for a specific category.
  """
  @spec get_category_endpoints(endpoint_category()) :: [endpoint_info()]
  def get_category_endpoints(category) do
    case Map.get(@coverage_matrix, category) do
      nil -> []
      endpoints -> Map.values(endpoints)
    end
  end

  @doc """
  Gets overall coverage statistics.
  """
  @spec get_coverage_stats() :: map()
  def get_coverage_stats do
    all_endpoints = get_all_endpoints()

    stats = %{
      total: length(all_endpoints),
      implemented: count_by_status(all_endpoints, :implemented),
      partial: count_by_status(all_endpoints, :partial),
      in_progress: count_by_status(all_endpoints, :in_progress),
      planned: count_by_status(all_endpoints, :planned),
      not_supported: count_by_status(all_endpoints, :not_supported),
      pve8_only: count_by_status(all_endpoints, :pve8_only),
      pve9_only: count_by_status(all_endpoints, :pve9_only)
    }

    coverage_percentage =
      (stats.implemented + stats.partial) / stats.total * 100

    Map.put(stats, :coverage_percentage, Float.round(coverage_percentage, 1))
  end

  @doc """
  Gets endpoints by implementation status.
  """
  @spec get_endpoints_by_status(implementation_status()) :: [endpoint_info()]
  def get_endpoints_by_status(status) do
    get_all_endpoints()
    |> Enum.filter(&(&1.status == status))
  end

  @doc """
  Gets endpoints by priority level.
  """
  @spec get_endpoints_by_priority(priority()) :: [endpoint_info()]
  def get_endpoints_by_priority(priority) do
    get_all_endpoints()
    |> Enum.filter(&(&1.priority == priority))
  end

  @doc """
  Gets critical endpoints that are not fully implemented.
  """
  @spec get_missing_critical_endpoints() :: [endpoint_info()]
  def get_missing_critical_endpoints do
    get_endpoints_by_priority(:critical)
    |> Enum.filter(&(&1.status != :implemented))
  end

  @doc """
  Gets coverage statistics by category.
  """
  @spec get_category_stats() :: map()
  def get_category_stats do
    @coverage_matrix
    |> Enum.map(fn {category, endpoints} ->
      endpoint_list = Map.values(endpoints)
      total = length(endpoint_list)
      implemented = length(Enum.filter(endpoint_list, &(&1.status == :implemented)))
      coverage = if total > 0, do: Float.round(implemented / total * 100, 1), else: 0.0

      {category,
       %{
         total: total,
         implemented: implemented,
         coverage_percentage: coverage
       }}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Validates coverage matrix for consistency and completeness.
  """
  @spec validate_coverage() :: {:ok, [String.t()]} | {:error, [String.t()]}
  def validate_coverage do
    issues = []

    # Check for endpoints without tests
    no_tests =
      get_all_endpoints()
      |> Enum.filter(&(!&1.test_coverage && &1.status == :implemented))
      |> Enum.map(&"Missing tests: #{&1.path}")

    # Check for missing critical endpoints
    missing_critical =
      get_missing_critical_endpoints()
      |> Enum.map(&"Critical endpoint not implemented: #{&1.path}")

    # Check for endpoints without handler modules
    no_handlers =
      get_all_endpoints()
      |> Enum.filter(&(is_nil(&1.handler_module) && &1.status == :implemented))
      |> Enum.map(&"Missing handler module: #{&1.path}")

    all_issues = issues ++ no_tests ++ missing_critical ++ no_handlers

    if length(all_issues) == 0 do
      {:ok, ["Coverage validation passed"]}
    else
      {:error, all_issues}
    end
  end

  @doc """
  Gets all supported categories.
  """
  @spec get_categories() :: [endpoint_category()]
  def get_categories do
    Map.keys(@coverage_matrix)
  end

  @doc """
  Returns the ordered list of category modules.
  """
  @spec category_modules() :: [module()]
  def category_modules, do: @category_modules

  @doc """
  Checks if an endpoint is version-compatible.
  """
  @spec version_compatible?(String.t(), String.t()) :: boolean()
  def version_compatible?(endpoint_path, pve_version) do
    case get_endpoint_info(endpoint_path) do
      nil ->
        false

      endpoint_info ->
        case endpoint_info.status do
          :pve8_only -> version_gte?(pve_version, "8.0")
          :pve9_only -> version_gte?(pve_version, "9.0")
          _ -> version_gte?(pve_version, endpoint_info.since)
        end
    end
  end

  # Private helper functions

  defp get_all_endpoints do
    @coverage_matrix
    |> Enum.flat_map(fn {_category, endpoints} -> Map.values(endpoints) end)
  end

  defp count_by_status(endpoints, status) do
    endpoints
    |> Enum.count(&(&1.status == status))
  end

  defp matches_pattern?(endpoint_path, pattern) do
    if endpoint_path == pattern do
      true
    else
      # Generic: replace any {param} with a segment matcher
      regex_str = Regex.replace(~r/\{[^}]+\}/, pattern, "[^/]+")
      Regex.match?(~r/^#{regex_str}$/, endpoint_path)
    end
  end

  defp version_gte?(version_a, version_b) do
    # Simple version comparison - could be enhanced with proper semver
    String.to_float(version_a) >= String.to_float(version_b)
  rescue
    # Default to true if version parsing fails
    _ -> true
  end
end
