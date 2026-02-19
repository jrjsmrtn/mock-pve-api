# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Docs.CoverageTest do
  use ExUnit.Case, async: false

  @output_path "docs/reference/api-reference.md"

  setup do
    # Save existing file content if present
    original =
      case File.read(@output_path) do
        {:ok, content} -> content
        {:error, _} -> nil
      end

    on_exit(fn ->
      # Restore original file
      if original do
        File.write!(@output_path, original)
      end
    end)

    :ok
  end

  describe "run/1" do
    test "generates API reference documentation" do
      Mix.Tasks.Docs.Coverage.run([])

      assert File.exists?(@output_path)
      content = File.read!(@output_path)

      # Verify key sections are present
      assert content =~ "Mock PVE API Reference"
      assert content =~ "Base Information"
      assert content =~ "Quick Start"
      assert content =~ "Coverage Overview"
      assert content =~ "Status Legend"
      assert content =~ "Error Responses"
      assert content =~ "Configuration"
      assert content =~ "Compatibility Notes"
      assert content =~ "auto-generated"
    end

    test "generates markdown with endpoint documentation" do
      Mix.Tasks.Docs.Coverage.run([])

      content = File.read!(@output_path)

      # Verify endpoint sections
      assert content =~ "/version"
      assert content =~ "/cluster"
      assert content =~ "/nodes"
      assert content =~ "/pools"
      assert content =~ "/access"
      assert content =~ "/storage"
    end

    test "generates category sections with tables" do
      Mix.Tasks.Docs.Coverage.run([])

      content = File.read!(@output_path)

      # Verify coverage table
      assert content =~ "| Category |"
      assert content =~ "| **TOTAL** |"
    end

    test "includes version badges and status icons" do
      Mix.Tasks.Docs.Coverage.run([])

      content = File.read!(@output_path)

      # Status icons should be present
      assert content =~ "✅"
    end

    test "includes parameter documentation for endpoints with params" do
      Mix.Tasks.Docs.Coverage.run([])

      content = File.read!(@output_path)

      # Some endpoints have parameters
      assert content =~ "**Parameters**"
    end

    test "includes example responses" do
      Mix.Tasks.Docs.Coverage.run([])

      content = File.read!(@output_path)

      # Example JSON responses
      assert content =~ "Example Response"
      assert content =~ "```json"
    end

    test "--check passes when docs are up-to-date" do
      # Generate docs first
      Mix.Tasks.Docs.Coverage.run([])

      # Check should pass
      assert Mix.Tasks.Docs.Coverage.run(["--check"]) == :ok
    end

    test "--check fails when docs are outdated" do
      # Write stale content
      File.mkdir_p!(Path.dirname(@output_path))
      File.write!(@output_path, "outdated content")

      assert catch_exit(Mix.Tasks.Docs.Coverage.run(["--check"])) == {:shutdown, 1}
    end

    test "--check fails when docs file is missing" do
      # Remove docs file
      File.rm(@output_path)

      assert catch_exit(Mix.Tasks.Docs.Coverage.run(["--check"])) == {:shutdown, 1}
    end
  end
end
