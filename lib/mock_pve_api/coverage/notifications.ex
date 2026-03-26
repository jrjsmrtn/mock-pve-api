# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Notifications do
  @moduledoc """
  PVE API coverage: Notification system endpoints (PVE 8.1+).

  Covers `/cluster/notifications/*` — endpoint types (gotify, sendmail, smtp, webhook),
  matchers, targets, and ancillary discovery endpoints.
  """

  @behaviour MockPveApi.Coverage.Category

  @impl true
  def category, do: :notifications

  @impl true
  def endpoints do
    implemented_endpoints()
  end

  defp implemented_endpoints do
    %{
      "/api2/json/cluster/notifications" => %{
        path: "/api2/json/cluster/notifications",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "8.1",
        description: "Notification system index — lists child resource names",
        parameters: [],
        response_schema: %{data: :array},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/endpoints" => %{
        path: "/api2/json/cluster/notifications/endpoints",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "8.1",
        description: "List available notification endpoint types",
        parameters: [],
        response_schema: %{data: :array},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/endpoints/gotify" => %{
        path: "/api2/json/cluster/notifications/endpoints/gotify",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "8.1",
        description: "List or create Gotify notification endpoints",
        parameters: [],
        response_schema: %{data: :array},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/endpoints/gotify/{name}" => %{
        path: "/api2/json/cluster/notifications/endpoints/gotify/{name}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "8.1",
        description: "Get, update, or delete a specific Gotify notification endpoint",
        parameters: [
          %{
            name: "name",
            type: :string,
            required: true,
            description: "Endpoint name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/endpoints/sendmail" => %{
        path: "/api2/json/cluster/notifications/endpoints/sendmail",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "8.1",
        description: "List or create sendmail notification endpoints",
        parameters: [],
        response_schema: %{data: :array},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/endpoints/sendmail/{name}" => %{
        path: "/api2/json/cluster/notifications/endpoints/sendmail/{name}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "8.1",
        description: "Get, update, or delete a specific sendmail notification endpoint",
        parameters: [
          %{
            name: "name",
            type: :string,
            required: true,
            description: "Endpoint name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/endpoints/smtp" => %{
        path: "/api2/json/cluster/notifications/endpoints/smtp",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "8.1",
        description: "List or create SMTP notification endpoints",
        parameters: [],
        response_schema: %{data: :array},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/endpoints/smtp/{name}" => %{
        path: "/api2/json/cluster/notifications/endpoints/smtp/{name}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "8.1",
        description: "Get, update, or delete a specific SMTP notification endpoint",
        parameters: [
          %{
            name: "name",
            type: :string,
            required: true,
            description: "Endpoint name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/endpoints/webhook" => %{
        path: "/api2/json/cluster/notifications/endpoints/webhook",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "8.2",
        description: "List or create webhook notification endpoints",
        parameters: [],
        response_schema: %{data: :array},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/endpoints/webhook/{name}" => %{
        path: "/api2/json/cluster/notifications/endpoints/webhook/{name}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "8.2",
        description: "Get, update, or delete a specific webhook notification endpoint",
        parameters: [
          %{
            name: "name",
            type: :string,
            required: true,
            description: "Endpoint name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/matchers" => %{
        path: "/api2/json/cluster/notifications/matchers",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "8.1",
        description: "List or create notification matchers",
        parameters: [],
        response_schema: %{data: :array},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/matchers/{name}" => %{
        path: "/api2/json/cluster/notifications/matchers/{name}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "8.1",
        description: "Get, update, or delete a specific notification matcher",
        parameters: [
          %{
            name: "name",
            type: :string,
            required: true,
            description: "Matcher name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/targets" => %{
        path: "/api2/json/cluster/notifications/targets",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "8.1",
        description: "List all notification targets across all endpoint types",
        parameters: [],
        response_schema: %{data: :array},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/targets/{name}/test" => %{
        path: "/api2/json/cluster/notifications/targets/{name}/test",
        methods: [:post],
        status: :implemented,
        priority: :low,
        since: "8.1",
        description: "Send a test notification to a target",
        parameters: [
          %{
            name: "name",
            type: :string,
            required: true,
            description: "Target name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :null},
        example_response: nil,
        capabilities_required: [:notification_endpoints],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/matcher-fields" => %{
        path: "/api2/json/cluster/notifications/matcher-fields",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "8.2",
        description: "List available matcher fields",
        parameters: [],
        response_schema: %{data: :array},
        example_response: nil,
        capabilities_required: [:notification_filters],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      },
      "/api2/json/cluster/notifications/matcher-field-values" => %{
        path: "/api2/json/cluster/notifications/matcher-field-values",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "8.2",
        description: "List possible values for matcher fields",
        parameters: [],
        response_schema: %{data: :object},
        example_response: nil,
        capabilities_required: [:notification_filters],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Notifications,
        notes: nil
      }
    }
  end
end
