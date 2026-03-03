# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :mock_pve_api,
      version: "0.4.19",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Mock Proxmox VE API Server for testing and development",
      package: package(),
      docs: docs(),
      name: "Mock PVE API",
      source_url: "https://github.com/jrjsmrtn/mock-pve-api"
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MockPveApi.Application, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.15"},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:finch, "~> 0.18"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:pve_openapi, path: "../pve-openapi", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      name: "mock_pve_api",
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/jrjsmrtn/mock-pve-api",
        "Documentation" => "https://hexdocs.pm/mock_pve_api"
      },
      maintainers: ["Georges Martin"]
    ]
  end

  defp docs do
    [
      main: "MockPveApi",
      extras: ["README.md", "CHANGELOG.md"],
      groups_for_modules: [
        Core: [MockPveApi, MockPveApi.Application],
        "API Handlers": [
          MockPveApi.Router,
          MockPveApi.Handlers.Version,
          MockPveApi.Handlers.Nodes,
          MockPveApi.Handlers.Storage,
          MockPveApi.Handlers.Cluster,
          MockPveApi.Handlers.Pools,
          MockPveApi.Handlers.Access,
          MockPveApi.Handlers.Metrics
        ],
        Infrastructure: [
          MockPveApi.State,
          MockPveApi.Capabilities,
          MockPveApi.Coverage,
          MockPveApi.Fixtures
        ]
      ]
    ]
  end
end
