defmodule ExpenseTrackerApiWeb.Schemas.ExpenseSchema do
  @moduledoc """
  OpenAPI schemas for Expense-related endpoints
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  defmodule Expense do
    @moduledoc "Schema for Expense model"

    OpenApiSpex.schema(%{
      title: "Expense",
      description: "A user expense record",
      type: :object,
      properties: %{
        id: %Schema{
          type: :integer,
          description: "Unique identifier for the expense",
          example: 1
        },
        amount: %Schema{
          type: :number,
          format: :decimal,
          description: "Expense amount in decimal format",
          minimum: 0.01,
          example: 25.50
        },
        description: %Schema{
          type: :string,
          description: "Description of the expense",
          minLength: 1,
          maxLength: 255,
          example: "Grocery shopping at local market"
        },
        category: %Schema{
          type: :string,
          description: "Expense category",
          enum: [:groceries, :leisure, :electronics, :utilities, :clothing, :health, :others],
          example: "groceries"
        },
        date: %Schema{
          type: :string,
          format: :date,
          description: "Date when the expense occurred (YYYY-MM-DD)",
          example: "2024-01-15"
        },
        currency: %Schema{
          type: :string,
          description: "ISO 4217 currency code (3 uppercase letters)",
          pattern: "^[A-Z]{3}$",
          example: "USD"
        },
        user_id: %Schema{
          type: :integer,
          description: "ID of the user who owns this expense",
          example: 1
        },
        inserted_at: %Schema{
          type: :string,
          format: :"date-time",
          description: "Timestamp when the expense was created",
          example: "2024-01-15T10:30:00Z"
        },
        updated_at: %Schema{
          type: :string,
          format: :"date-time",
          description: "Timestamp when the expense was last updated",
          example: "2024-01-15T10:30:00Z"
        }
      },
      required: [:amount, :description, :category, :currency, :user_id],
      example: %{
        id: 1,
        amount: 25.50,
        description: "Grocery shopping at local market",
        category: "groceries",
        date: "2024-01-15",
        currency: "USD",
        user_id: 1,
        inserted_at: "2024-01-15T10:30:00Z",
        updated_at: "2024-01-15T10:30:00Z"
      }
    })
  end
  defmodule ExpenseRequest do
    @moduledoc "Schema for creating or updating an expense"

    OpenApiSpex.schema(%{
      title: "ExpenseRequest",
      description: "Request body for creating or updating an expense",
      type: :object,
      properties: %{
        amount: %Schema{
          type: :number,
          format: :decimal,
          description: "Expense amount in decimal format",
          minimum: 0.01,
          example: 25.50
        },
        description: %Schema{
          type: :string,
          description: "Description of the expense",
          minLength: 1,
          maxLength: 255,
          example: "Grocery shopping at local market"
        },
        category: %Schema{
          type: :string,
          description: "Expense category",
          enum: [:groceries, :leisure, :electronics, :utilities, :clothing, :health, :others],
          example: "groceries"
        },
        date: %Schema{
          type: :string,
          format: :date,
          description: "Date when the expense occurred (YYYY-MM-DD). Defaults to today if not provided",
          example: "2024-01-15"
        },
        currency: %Schema{
          type: :string,
          description: "ISO 4217 currency code (3 uppercase letters). Defaults to USD if not provided",
          pattern: "^[A-Z]{3}$",
          example: "USD"
        }
      },
      required: [:amount, :description],
      example: %{
        amount: 25.50,
        description: "Grocery shopping at local market",
        category: "groceries",
        date: "2024-01-15",
        currency: "USD"
      }
    })
  end
  defmodule ExpenseResponse do
    @moduledoc "Schema for single expense response"

    OpenApiSpex.schema(%{
      title: "ExpenseResponse",
      description: "Response containing a single expense",
      type: :object,
      properties: %{
        data: Expense,
        message: %Schema{
          type: :string,
          description: "Success message",
          example: "Expense retrieved successfully"
        }
      },
      required: [:data],
      example: %{
        data: %{
          id: 1,
          amount: 25.50,
          description: "Grocery shopping at local market",
          category: "groceries",
          date: "2024-01-15",
          currency: "USD",
          user_id: 1,
          inserted_at: "2024-01-15T10:30:00Z",
          updated_at: "2024-01-15T10:30:00Z"
        },
        message: "Expense retrieved successfully"
      }
    })
  end
  defmodule ExpenseListResponse do
    @moduledoc "Schema for expense list response"

    OpenApiSpex.schema(%{
      title: "ExpenseListResponse",
      description: "Response containing a list of expenses with pagination info",
      type: :object,
      properties: %{
        data: %Schema{
          type: :array,
          items: Expense,
          description: "Array of expense objects"
        },
        meta: %Schema{
          type: :object,
          description: "Metadata about the response",
          properties: %{
            total_count: %Schema{
              type: :integer,
              description: "Total number of expenses for the user",
              example: 150
            },
            page: %Schema{
              type: :integer,
              description: "Current page number",
              example: 1
            },
            per_page: %Schema{
              type: :integer,
              description: "Number of items per page",
              example: 20
            },
            total_pages: %Schema{
              type: :integer,
              description: "Total number of pages",
              example: 8
            }
          }
        },
        message: %Schema{
          type: :string,
          description: "Success message",
          example: "Expenses retrieved successfully"
        }
      },
      required: [:data],
      example: %{
        data: [
          %{
            id: 1,
            amount: 25.50,
            description: "Grocery shopping at local market",
            category: "groceries",
            date: "2024-01-15",
            currency: "USD",
            user_id: 1,
            inserted_at: "2024-01-15T10:30:00Z",
            updated_at: "2024-01-15T10:30:00Z"
          },
          %{
            id: 2,
            amount: 12.99,
            description: "Coffee and pastry",
            category: "leisure",
            date: "2024-01-14",
            currency: "EUR",
            user_id: 1,
            inserted_at: "2024-01-14T08:15:00Z",
            updated_at: "2024-01-14T08:15:00Z"
          }
        ],
        meta: %{
          total_count: 150,
          page: 1,
          per_page: 20,
          total_pages: 8
        },
        message: "Expenses retrieved successfully"
      }
    })
  end
end
