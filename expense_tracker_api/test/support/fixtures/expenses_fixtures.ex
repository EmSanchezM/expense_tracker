defmodule ExpenseTrackerApi.ExpensesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExpenseTrackerApi.Expenses` context.
  """

  import ExpenseTrackerApi.AccountsFixtures

  def valid_expense_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      "amount" => "100.50",
      "description" => "Test expense",
      "category" => "groceries",
      "date" => Date.utc_today()
    })
  end

  def expense_fixture(user \\ nil, attrs \\ %{}) do
    user = user || user_fixture()

    {:ok, expense} =
      attrs
      |> valid_expense_attributes()
      |> then(&ExpenseTrackerApi.Expenses.create_expense(user.id, &1))

    expense
  end
end
