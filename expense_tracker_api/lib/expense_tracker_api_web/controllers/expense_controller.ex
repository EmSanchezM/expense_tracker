defmodule ExpenseTrackerApiWeb.ExpenseController do
  use ExpenseTrackerApiWeb, :controller

  alias ExpenseTrackerApi.Expenses
  alias Guardian.Plug

  action_fallback ExpenseTrackerApiWeb.FallbackController

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
