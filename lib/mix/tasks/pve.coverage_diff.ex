# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Pve.CoverageDiff do
  use Mix.Task

  alias MockPveApi.Coverage
  alias MockPveApi.EndpointMatrix

  @shortdoc "Diff EndpointMatrix against Coverage catalog"

  @moduledoc """
  Compares the EndpointMatrix (generated from pve-openapi) against the Coverage
  catalog to identify gaps, method mismatches, and `since` conflicts.

  ## Usage

      mix pve.coverage_diff               # Full diff report
      mix pve.coverage_diff --section X   # Filter to one API section (e.g., "access", "cluster")
      mix pve.coverage_diff --summary     # Counts only, no endpoint listing
      mix pve.coverage_diff --since 8.0   # Only show endpoints added in PVE 8.0+
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("compile", [])

    {opts, _, _} =
      OptionParser.parse(args,
        strict: [section: :string, summary: :boolean, since: :string]
      )

    section_filter = Keyword.get(opts, :section)
    summary_only = Keyword.get(opts, :summary, false)
    since_filter = Keyword.get(opts, :since)

    matrix_by_path = collect_matrix_by_path()
    coverage_by_path = collect_coverage_by_path()

    missing = compute_missing(matrix_by_path, coverage_by_path)
    extra = compute_extra(matrix_by_path, coverage_by_path)
    method_mismatches = compute_method_mismatches(matrix_by_path, coverage_by_path)
    since_conflicts = compute_since_conflicts(coverage_by_path)

    missing = apply_missing_filters(missing, section_filter, since_filter)
    extra = apply_pair_filter(extra, section_filter)
    method_mismatches = apply_triple_filter(method_mismatches, section_filter)
    since_conflicts = apply_triple_filter(since_conflicts, section_filter)

    print_header(matrix_by_path, coverage_by_path)
    print_summary(missing, extra, method_mismatches, since_conflicts)

    unless summary_only do
      print_missing_by_section(missing)
      print_method_mismatches(method_mismatches)
      print_since_conflicts(since_conflicts)
    end
  end

  # --- Data collection ---

  defp collect_matrix_by_path do
    EndpointMatrix.versions()
    |> Enum.reduce(MapSet.new(), fn version, acc ->
      MapSet.union(acc, EndpointMatrix.endpoints_for(version))
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(fn {path, methods} -> {path, MapSet.new(methods)} end)
  end

  defp collect_coverage_by_path do
    Coverage.category_modules()
    |> Enum.flat_map(fn mod -> mod.endpoints() |> Enum.to_list() end)
    |> Map.new()
  end

  # --- Diff computations ---

  defp compute_missing(matrix_by_path, coverage_by_path) do
    coverage_methods =
      Map.new(coverage_by_path, fn {path, info} -> {path, MapSet.new(info.methods)} end)

    matrix_by_path
    |> Enum.flat_map(fn {path, methods} ->
      covered = Map.get(coverage_methods, path, MapSet.new())

      methods
      |> MapSet.difference(covered)
      |> Enum.map(fn method ->
        {path, method, EndpointMatrix.added_in(path, method)}
      end)
    end)
    |> Enum.sort()
  end

  defp compute_extra(matrix_by_path, coverage_by_path) do
    coverage_by_path
    |> Enum.flat_map(fn {path, info} ->
      matrix_methods = Map.get(matrix_by_path, path, MapSet.new())

      info.methods
      |> Enum.reject(&MapSet.member?(matrix_methods, &1))
      |> Enum.map(fn method -> {path, method} end)
    end)
    |> Enum.sort()
  end

  defp compute_method_mismatches(matrix_by_path, coverage_by_path) do
    coverage_by_path
    |> Enum.filter(fn {path, _} -> Map.has_key?(matrix_by_path, path) end)
    |> Enum.map(fn {path, info} ->
      {path, matrix_by_path[path], MapSet.new(info.methods)}
    end)
    |> Enum.filter(fn {_path, matrix, coverage} -> matrix != coverage end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  defp compute_since_conflicts(coverage_by_path) do
    coverage_by_path
    |> Enum.flat_map(fn {path, info} ->
      matrix_since = EndpointMatrix.added_in(path, hd(info.methods))

      if matrix_since && since_conflict?(info.since, matrix_since) do
        [{path, info.since, matrix_since}]
      else
        []
      end
    end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  defp since_conflict?(coverage_since, matrix_since) do
    {cov_major, _} = parse_version(coverage_since)
    {mat_major, _} = parse_version(matrix_since)
    cov_major != mat_major
  end

  defp parse_version(version_string) do
    [major, minor] =
      version_string |> String.split(".") |> Enum.take(2) |> Enum.map(&String.to_integer/1)

    {major, minor}
  end

  # --- Filters ---

  defp apply_missing_filters(missing, section, since) do
    missing
    |> filter_by_section(section, fn {path, _, _} -> path end)
    |> apply_since_filter(since)
  end

  defp apply_pair_filter(list, section) do
    filter_by_section(list, section, fn {path, _} -> path end)
  end

  defp apply_triple_filter(list, section) do
    filter_by_section(list, section, fn {path, _, _} -> path end)
  end

  defp filter_by_section(list, nil, _path_fn), do: list

  defp filter_by_section(list, section, path_fn) do
    Enum.filter(list, fn entry -> section_from_path(path_fn.(entry)) == section end)
  end

  defp apply_since_filter(list, nil), do: list

  defp apply_since_filter(list, threshold_str) do
    threshold = parse_version(threshold_str)
    Enum.filter(list, fn {_, _, since} -> since != nil && parse_version(since) >= threshold end)
  end

  defp section_from_path("/api2/json/" <> rest), do: rest |> String.split("/", parts: 2) |> hd()
  defp section_from_path(path), do: path

  # --- Output ---

  defp print_header(matrix_by_path, coverage_by_path) do
    matrix_count =
      Enum.reduce(matrix_by_path, 0, fn {_, methods}, acc -> acc + MapSet.size(methods) end)

    coverage_count =
      Enum.reduce(coverage_by_path, 0, fn {_, info}, acc -> acc + length(info.methods) end)

    versions = EndpointMatrix.versions()
    version_range = "#{hd(versions)}-#{List.last(versions)}"

    Mix.shell().info(
      "EndpointMatrix: #{matrix_count} endpoints " <>
        "(pve-openapi v#{EndpointMatrix.pve_openapi_version()}, " <>
        "#{length(versions)} versions: #{version_range})"
    )

    Mix.shell().info("Coverage catalog: #{coverage_count} endpoints")
    Mix.shell().info("")
  end

  defp print_summary(missing, extra, method_mismatches, since_conflicts) do
    Mix.shell().info("Missing from coverage: #{length(missing)}")
    Mix.shell().info("Extra in coverage: #{length(extra)}")
    Mix.shell().info("Method mismatches: #{length(method_mismatches)}")
    Mix.shell().info("Since conflicts: #{length(since_conflicts)}")
    Mix.shell().info("")
  end

  defp print_missing_by_section([]), do: :ok

  defp print_missing_by_section(missing) do
    max_path_len = missing |> Enum.map(fn {path, _, _} -> String.length(path) end) |> Enum.max()

    by_section =
      missing
      |> Enum.group_by(fn {path, _, _} -> section_from_path(path) end)
      |> Enum.sort_by(&elem(&1, 0))

    Mix.shell().info("Missing by section:")

    for {section, entries} <- by_section do
      Mix.shell().info("  /#{section} (#{length(entries)} missing):")

      for {path, method, since} <- Enum.sort(entries) do
        method_str = method |> Atom.to_string() |> String.upcase() |> String.pad_trailing(7)
        padded_path = String.pad_trailing(path, max_path_len)
        since_str = if since, do: "since #{since}", else: "since ?"
        Mix.shell().info("    #{method_str}#{padded_path}  #{since_str}")
      end
    end

    Mix.shell().info("")
  end

  defp print_method_mismatches([]), do: :ok

  defp print_method_mismatches(mismatches) do
    Mix.shell().info("Method mismatches:")

    for {path, matrix_methods, coverage_methods} <- mismatches do
      Mix.shell().info(
        "  #{path}: matrix=#{format_methods(matrix_methods)} coverage=#{format_methods(coverage_methods)}"
      )
    end

    Mix.shell().info("")
  end

  defp print_since_conflicts([]), do: :ok

  defp print_since_conflicts(conflicts) do
    Mix.shell().info("Since conflicts:")

    for {path, cov_since, mat_since} <- conflicts do
      Mix.shell().info("  #{path}: coverage=\"#{cov_since}\" matrix=\"#{mat_since}\"")
    end

    Mix.shell().info("")
  end

  defp format_methods(method_set) do
    str =
      method_set
      |> Enum.sort()
      |> Enum.map_join(",", fn m -> m |> Atom.to_string() |> String.upcase() end)

    "[#{str}]"
  end
end
