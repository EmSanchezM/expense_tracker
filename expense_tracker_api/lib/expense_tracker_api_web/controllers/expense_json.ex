defmodule ExpenseTrackerApiWeb.ExpenseJSON do
  @moduledoc """
  Renders expense data.
  """

  @doc """
  Renders a list of expenses.
  """
  def index(%{expenses: expenses}) do
    %{
      data: for(expense <- expenses, do: data(expense))
    }
  end

  @doc """
  Renders a single expense.
  """
  def show(%{expense: expense}) do
    %{
      data: data(expense)
    }
  end

  @doc """
  Renders success message for delete operations.
  """
  def delete(_assigns) do
    %{
      data: %{
        message: "Expense deleted successfully"
      }
    }
  end

  defp data(expense) do
    %{
      id: expense.id,
      amount: expense.amount,
      description: expense.description,
      category: expense.category,
      date: expense.date,
      currency: expense.currency,
      inserted_at: expense.inserted_at,
      updated_at: expense.updated_at
    }
  end
end
