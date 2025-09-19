defmodule ExpenseTrackerApiWeb.Schemas.ErrorSchema do
  @moduledoc """
  OpenAPI schemas for Error responses
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  defmodule ValidationError do
    @moduledoc "Schema for validation error responses (422)"

    OpenApiSpex.schema(%{
      title: "ValidationError",
      description: "Validation error response with field-level error details",
      type: :object,
      properties: %{
        error: %Schema{
          type: :string,
          description: "General error message",
          example: "Validation failed"
        },
        errors: %Schema{
          type: :object,
          description: "Field-level validation errors",
          additionalProperties: %Schema{
            type: :array,
            items: %Schema{type: :string},
            description: "Array of error messages for this field"
          },
          example: %{
            "amount" => ["can't be blank", "must be greater than 0"],
            "description" => ["can't be blank", "should be at most 255 character(s)"],
            "category" => ["is invalid"]
          }
        },
        message: %Schema{
          type: :string,
          description: "Human-readable error message",
          example: "The request contains invalid data"
        }
      },
      required: [:error, :errors],
      example: %{
        error: "Validation failed",
        errors: %{
          "amount" => ["can't be blank", "must be greater than 0"],
          "description" => ["can't be blank", "should be at most 255 character(s)"],
          "category" => ["is invalid"]
        },
        message: "The request contains invalid data"
      }
    })
  end

  defmodule NotFoundError do
    @moduledoc "Schema for not found error responses (404)"

    OpenApiSpex.schema(%{
      title: "NotFoundError",
      description: "Resource not found error response",
      type: :object,
      properties: %{
        error: %Schema{
          type: :string,
          description: "Error type identifier",
          example: "not_found"
        },
        message: %Schema{
          type: :string,
          description: "Human-readable error message",
          example: "The requested resource was not found"
        },
        details: %Schema{
          type: :string,
          description: "Additional details about the error",
          example: "Expense with ID 999 does not exist or does not belong to the current user"
        }
      },
      required: [:error, :message],
      example: %{
        error: "not_found",
        message: "The requested resource was not found",
        details: "Expense with ID 999 does not exist or does not belong to the current user"
      }
    })
  end

  defmodule UnauthorizedError do
    @moduledoc "Schema for unauthorized error responses (401)"

    OpenApiSpex.schema(%{
      title: "UnauthorizedError",
      description: "Authentication required or invalid credentials error response",
      type: :object,
      properties: %{
        error: %Schema{
          type: :string,
          description: "Error type identifier",
          example: "unauthorized"
        },
        message: %Schema{
          type: :string,
          description: "Human-readable error message",
          example: "Authentication required"
        },
        details: %Schema{
          type: :string,
          description: "Additional details about the authentication error",
          example: "Invalid or expired JWT token"
        }
      },
      required: [:error, :message],
      example: %{
        error: "unauthorized",
        message: "Authentication required",
        details: "Invalid or expired JWT token"
      }
    })
  end

  defmodule InternalServerError do
    @moduledoc "Schema for internal server error responses (500)"

    OpenApiSpex.schema(%{
      title: "InternalServerError",
      description: "Internal server error response",
      type: :object,
      properties: %{
        error: %Schema{
          type: :string,
          description: "Error type identifier",
          example: "internal_server_error"
        },
        message: %Schema{
          type: :string,
          description: "Human-readable error message",
          example: "An unexpected error occurred"
        },
        request_id: %Schema{
          type: :string,
          description: "Unique request identifier for debugging",
          example: "req_1234567890abcdef"
        }
      },
      required: [:error, :message],
      example: %{
        error: "internal_server_error",
        message: "An unexpected error occurred",
        request_id: "req_1234567890abcdef"
      }
    })
  end

  defmodule ForbiddenError do
    @moduledoc "Schema for forbidden error responses (403)"

    OpenApiSpex.schema(%{
      title: "ForbiddenError",
      description: "Access forbidden error response",
      type: :object,
      properties: %{
        error: %Schema{
          type: :string,
          description: "Error type identifier",
          example: "forbidden"
        },
        message: %Schema{
          type: :string,
          description: "Human-readable error message",
          example: "Access denied"
        },
        details: %Schema{
          type: :string,
          description: "Additional details about the access restriction",
          example: "You don't have permission to access this resource"
        }
      },
      required: [:error, :message],
      example: %{
        error: "forbidden",
        message: "Access denied",
        details: "You don't have permission to access this resource"
      }
    })
  end
end
