defmodule ExpenseTrackerApiWeb.Schemas.HealthSchema do
  @moduledoc """
  OpenAPI schemas for Health check responses
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  defmodule HealthResponse do
    @moduledoc "Schema for health check response"

    OpenApiSpex.schema(%{
      title: "HealthResponse",
      description: "API health status response",
      type: :object,
      properties: %{
        status: %Schema{
          type: :string,
          description: "API status indicator",
          example: "ok"
        },
        message: %Schema{
          type: :string,
          description: "Human-readable status message",
          example: "Expense Tracker API is running"
        },
        timestamp: %Schema{
          type: :string,
          format: :"date-time",
          description: "Current server timestamp in ISO 8601 format",
          example: "2024-01-15T10:30:00.000000Z"
        }
      },
      required: [:status, :message, :timestamp],
      example: %{
        status: "ok",
        message: "Expense Tracker API is running",
        timestamp: "2024-01-15T10:30:00.000000Z"
      }
    })
  end
end
