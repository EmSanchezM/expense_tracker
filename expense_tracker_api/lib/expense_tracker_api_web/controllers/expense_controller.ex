defmodule ExpenseTrackerApiWeb.ExpenseController do
  use ExpenseTrackerApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias ExpenseTrackerApi.Expenses
  alias Guardian.Plug
  alias ExpenseTrackerApiWeb.Schemas.ExpenseSchema
  alias ExpenseTrackerApiWeb.Schemas.ErrorSchema

  action_fallback(ExpenseTrackerApiWeb.FallbackController)

  tags(["Expenses"])

  operation(:index,
    summary: "List user expenses",
    description:
      "Retrieve a list of expenses for the authenticated user with optional filtering by time period or date range",
    parameters: [
      period: [
        in: :query,
        description: "Predefined time period filter",
        schema: %OpenApiSpex.Schema{
          type: :string,
          enum: ["last_week", "last_month", "last_3_months"]
        },
        example: "last_month"
      ],
      from_date: [
        in: :query,
        description: "Start date for custom date range filter (YYYY-MM-DD format)",
        schema: %OpenApiSpex.Schema{type: :string, format: :date},
        example: "2024-01-01"
      ],
      to_date: [
        in: :query,
        description: "End date for custom date range filter (YYYY-MM-DD format)",
        schema: %OpenApiSpex.Schema{type: :string, format: :date},
        example: "2024-01-31"
      ]
    ],
    responses: [
      ok:
        {"Expenses retrieved successfully", "application/json", ExpenseSchema.ExpenseListResponse},
      unauthorized: {"Authentication required", "application/json", ErrorSchema.UnauthorizedError}
    ],
    security: [%{"bearerAuth" => []}]
  )

  @doc """
  List user expenses with optional date filters
  """
  def index(conn, params) do
    user = Plug.current_resource(conn)
    filters = build_filters(params)

    expenses = Expenses.list_user_expenses(user.id, filters)

    conn
    |> put_status(:ok)
    |> render(:index, expenses: expenses)
  end

  operation(:create,
    summary: "Create a new expense",
    description: "Create a new expense record for the authenticated user",
    request_body:
      {"Expense data", "application/json",
       %OpenApiSpex.Schema{
         type: :object,
         properties: %{
           expense: ExpenseSchema.ExpenseRequest
         },
         required: [:expense]
       }},
    responses: [
      created:
        {"Expense created successfully", "application/json", ExpenseSchema.ExpenseResponse},
      unauthorized:
        {"Authentication required", "application/json", ErrorSchema.UnauthorizedError},
      unprocessable_entity: {"Validation errors", "application/json", ErrorSchema.ValidationError}
    ],
    security: [%{"bearerAuth" => []}]
  )

  @doc """
  Create a new expense
  """
  def create(conn, %{"expense" => expense_params}) do
    user = Plug.current_resource(conn)

    case Expenses.create_expense(user.id, expense_params) do
      {:ok, expense} ->
        conn
        |> put_status(:created)
        |> render(:show, expense: expense)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ExpenseTrackerApiWeb.ErrorJSON)
        |> render(:validation_error, changeset: changeset)
    end
  end

  operation(:show,
    summary: "Get a specific expense",
    description: "Retrieve a single expense by ID for the authenticated user",
    parameters: [
      id: [
        in: :path,
        description: "Expense ID",
        schema: %OpenApiSpex.Schema{type: :integer},
        example: 1
      ]
    ],
    responses: [
      ok: {"Expense retrieved successfully", "application/json", ExpenseSchema.ExpenseResponse},
      unauthorized:
        {"Authentication required", "application/json", ErrorSchema.UnauthorizedError},
      not_found: {"Expense not found", "application/json", ErrorSchema.NotFoundError}
    ],
    security: [%{"bearerAuth" => []}]
  )

  @doc """
  Get a specific expense
  """
  def show(conn, %{"id" => id}) do
    user = Plug.current_resource(conn)

    try do
      expense = Expenses.get_user_expense!(user.id, id)

      conn
      |> put_status(:ok)
      |> render(:show, expense: expense)
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> put_view(ExpenseTrackerApiWeb.ErrorJSON)
        |> render(:not_found, message: "Expense not found")
    end
  end

  operation(:update,
    summary: "Update an expense",
    description: "Update an existing expense for the authenticated user",
    parameters: [
      id: [
        in: :path,
        description: "Expense ID",
        schema: %OpenApiSpex.Schema{type: :integer},
        example: 1
      ]
    ],
    request_body:
      {"Updated expense data", "application/json",
       %OpenApiSpex.Schema{
         type: :object,
         properties: %{
           expense: ExpenseSchema.ExpenseRequest
         },
         required: [:expense]
       }},
    responses: [
      ok: {"Expense updated successfully", "application/json", ExpenseSchema.ExpenseResponse},
      unauthorized:
        {"Authentication required", "application/json", ErrorSchema.UnauthorizedError},
      not_found: {"Expense not found", "application/json", ErrorSchema.NotFoundError},
      unprocessable_entity: {"Validation errors", "application/json", ErrorSchema.ValidationError}
    ],
    security: [%{"bearerAuth" => []}]
  )

  @doc """
  Update an expense
  """
  def update(conn, %{"id" => id, "expense" => expense_params}) do
    user = Plug.current_resource(conn)

    try do
      expense = Expenses.get_user_expense!(user.id, id)

      case Expenses.update_expense(expense, expense_params) do
        {:ok, updated_expense} ->
          conn
          |> put_status(:ok)
          |> render(:show, expense: updated_expense)

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> put_view(ExpenseTrackerApiWeb.ErrorJSON)
          |> render(:validation_error, changeset: changeset)
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> put_view(ExpenseTrackerApiWeb.ErrorJSON)
        |> render(:not_found, message: "Expense not found")
    end
  end

  operation(:delete,
    summary: "Delete an expense",
    description: "Delete an existing expense for the authenticated user",
    parameters: [
      id: [
        in: :path,
        description: "Expense ID",
        schema: %OpenApiSpex.Schema{type: :integer},
        example: 1
      ]
    ],
    responses: [
      ok:
        {"Expense deleted successfully", "application/json",
         %OpenApiSpex.Schema{
           type: :object,
           properties: %{
             message: %OpenApiSpex.Schema{
               type: :string,
               example: "Expense deleted successfully"
             }
           }
         }},
      unauthorized:
        {"Authentication required", "application/json", ErrorSchema.UnauthorizedError},
      not_found: {"Expense not found", "application/json", ErrorSchema.NotFoundError},
      internal_server_error:
        {"Internal server error", "application/json", ErrorSchema.InternalServerError}
    ],
    security: [%{"bearerAuth" => []}]
  )

  @doc """
  Delete an expense
  """
  def delete(conn, %{"id" => id}) do
    user = Plug.current_resource(conn)

    try do
      expense = Expenses.get_user_expense!(user.id, id)

      case Expenses.delete_expense(expense) do
        {:ok, _expense} ->
          conn
          |> put_status(:ok)
          |> render(:delete)

        {:error, %Ecto.Changeset{}} ->
          conn
          |> put_status(:internal_server_error)
          |> put_view(ExpenseTrackerApiWeb.ErrorJSON)
          |> render(:internal_server_error)
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> put_view(ExpenseTrackerApiWeb.ErrorJSON)
        |> render(:not_found, message: "Expense not found")
    end
  end

  # Private helper functions

  defp build_filters(params) do
    filters = %{}

    filters
    |> maybe_add_period_filter(params)
    |> maybe_add_date_range_filter(params)
  end

  defp maybe_add_period_filter(filters, %{"period" => period})
       when period in ["last_week", "last_month", "last_3_months"] do
    Map.put(filters, :period, period)
  end

  defp maybe_add_period_filter(filters, _params), do: filters

  defp maybe_add_date_range_filter(filters, %{"from_date" => from_date, "to_date" => to_date}) do
    with {:ok, parsed_from} <- Date.from_iso8601(from_date),
         {:ok, parsed_to} <- Date.from_iso8601(to_date) do
      filters
      |> Map.put(:from_date, parsed_from)
      |> Map.put(:to_date, parsed_to)
    else
      _ -> filters
    end
  end

  defp maybe_add_date_range_filter(filters, %{"from_date" => from_date}) do
    case Date.from_iso8601(from_date) do
      {:ok, parsed_date} -> Map.put(filters, :from_date, parsed_date)
      _ -> filters
    end
  end

  defp maybe_add_date_range_filter(filters, %{"to_date" => to_date}) do
    case Date.from_iso8601(to_date) do
      {:ok, parsed_date} -> Map.put(filters, :to_date, parsed_date)
      _ -> filters
    end
  end

  defp maybe_add_date_range_filter(filters, _params), do: filters
end
