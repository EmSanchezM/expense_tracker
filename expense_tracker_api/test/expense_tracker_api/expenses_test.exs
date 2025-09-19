defmodule ExpenseTrackerApi.ExpensesTest do
  use ExpenseTrackerApi.DataCase

  alias ExpenseTrackerApi.Expenses
  alias ExpenseTrackerApi.Expenses.Expense

  import ExpenseTrackerApi.AccountsFixtures
  import ExpenseTrackerApi.ExpensesFixtures

  describe "create_expense/2" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "creates an expense with valid data", %{user: user} do
      valid_attrs = valid_expense_attributes()

      assert {:ok, %Expense{} = expense} = Expenses.create_expense(user.id, valid_attrs)
      assert expense.amount == Decimal.new("100.50")
      assert expense.description == "Test expense"
      assert expense.category == :groceries
      assert expense.date == Date.utc_today()
      assert expense.user_id == user.id
    end

    test "creates expense with default date when not provided", %{user: user} do
      attrs = valid_expense_attributes(%{date: nil})

      assert {:ok, %Expense{} = expense} = Expenses.create_expense(user.id, attrs)
      assert expense.date == Date.utc_today()
    end

    test "creates expense with default category when not provided", %{user: user} do
      attrs = valid_expense_attributes(%{category: nil})

      assert {:ok, %Expense{} = expense} = Expenses.create_expense(user.id, attrs)
      assert expense.category == :others
    end

    test "returns error changeset with invalid amount", %{user: user} do
      invalid_attrs = valid_expense_attributes(%{amount: "invalid"})

      assert {:error, %Ecto.Changeset{} = changeset} = Expenses.create_expense(user.id, invalid_attrs)
      assert %{amount: ["is invalid"]} = errors_on(changeset)
    end

    test "returns error changeset with negative amount", %{user: user} do
      invalid_attrs = valid_expense_attributes(%{amount: "-10.50"})

      assert {:error, %Ecto.Changeset{} = changeset} = Expenses.create_expense(user.id, invalid_attrs)
      assert %{amount: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "returns error changeset with zero amount", %{user: user} do
      invalid_attrs = valid_expense_attributes(%{amount: "0"})

      assert {:error, %Ecto.Changeset{} = changeset} = Expenses.create_expense(user.id, invalid_attrs)
      assert %{amount: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "returns error changeset with missing description", %{user: user} do
      invalid_attrs = valid_expense_attributes(%{description: nil})

      assert {:error, %Ecto.Changeset{} = changeset} = Expenses.create_expense(user.id, invalid_attrs)
      assert %{description: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with empty description", %{user: user} do
      invalid_attrs = valid_expense_attributes(%{description: ""})

      assert {:error, %Ecto.Changeset{} = changeset} = Expenses.create_expense(user.id, invalid_attrs)
      assert %{description: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with too long description", %{user: user} do
      long_description = String.duplicate("a", 256)
      invalid_attrs = valid_expense_attributes(%{description: long_description})

      assert {:error, %Ecto.Changeset{} = changeset} = Expenses.create_expense(user.id, invalid_attrs)
      assert %{description: ["should be at most 255 character(s)"]} = errors_on(changeset)
    end

    test "returns error changeset with invalid category", %{user: user} do
      invalid_attrs = valid_expense_attributes(%{category: "invalid_category"})

      assert {:error, %Ecto.Changeset{} = changeset} = Expenses.create_expense(user.id, invalid_attrs)
      assert %{category: ["is invalid"]} = errors_on(changeset)
    end

    test "returns error changeset with missing amount", %{user: user} do
      invalid_attrs = valid_expense_attributes(%{amount: nil})

      assert {:error, %Ecto.Changeset{} = changeset} = Expenses.create_expense(user.id, invalid_attrs)
      assert %{amount: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "get_user_expense!/2" do
    setup do
      user = user_fixture()
      other_user = user_fixture()
      expense = expense_fixture(user)
      %{user: user, other_user: other_user, expense: expense}
    end

    test "returns the expense when it belongs to the user", %{user: user, expense: expense} do
      retrieved_expense = Expenses.get_user_expense!(user.id, expense.id)

      assert retrieved_expense.id == expense.id
      assert retrieved_expense.user_id == user.id
      assert retrieved_expense.amount == expense.amount
      assert retrieved_expense.description == expense.description
    end

    test "raises Ecto.NoResultsError when expense doesn't belong to user", %{other_user: other_user, expense: expense} do
      assert_raise Ecto.NoResultsError, fn ->
        Expenses.get_user_expense!(other_user.id, expense.id)
      end
    end

    test "raises Ecto.NoResultsError when expense doesn't exist", %{user: user} do
      assert_raise Ecto.NoResultsError, fn ->
        Expenses.get_user_expense!(user.id, 999)
      end
    end
  end

  describe "update_expense/2" do
    setup do
      user = user_fixture()
      expense = expense_fixture(user)
      %{user: user, expense: expense}
    end

    test "updates the expense with valid data", %{expense: expense} do
      update_attrs = %{
        amount: "200.75",
        description: "Updated expense",
        category: "electronics"
      }

      assert {:ok, %Expense{} = updated_expense} = Expenses.update_expense(expense, update_attrs)
      assert updated_expense.amount == Decimal.new("200.75")
      assert updated_expense.description == "Updated expense"
      assert updated_expense.category == :electronics
      assert updated_expense.id == expense.id
    end

    test "returns error changeset with invalid data", %{expense: expense} do
      invalid_attrs = %{amount: "invalid", description: ""}

      assert {:error, %Ecto.Changeset{} = changeset} = Expenses.update_expense(expense, invalid_attrs)
      errors = errors_on(changeset)
      assert %{amount: ["is invalid"]} = errors
      assert %{description: ["can't be blank"]} = errors
    end

    test "returns error changeset with negative amount", %{expense: expense} do
      invalid_attrs = %{amount: "-50.00"}

      assert {:error, %Ecto.Changeset{} = changeset} = Expenses.update_expense(expense, invalid_attrs)
      assert %{amount: ["must be greater than 0"]} = errors_on(changeset)
    end
  end

  describe "delete_expense/1" do
    setup do
      user = user_fixture()
      expense = expense_fixture(user)
      %{user: user, expense: expense}
    end

    test "deletes the expense", %{expense: expense} do
      assert {:ok, %Expense{}} = Expenses.delete_expense(expense)
      assert_raise Ecto.NoResultsError, fn -> Expenses.get_user_expense!(expense.user_id, expense.id) end
    end
  end

  describe "list_user_expenses/2" do
    setup do
      user = user_fixture()
      other_user = user_fixture()

      # Create expenses with different dates
      today = Date.utc_today()
      last_week = Date.add(today, -5)
      last_month = Date.add(today, -20)
      three_months_ago = Date.add(today, -80)

      expense_today = expense_fixture(user, %{description: "Today expense", date: today})
      expense_last_week = expense_fixture(user, %{description: "Last week expense", date: last_week})
      expense_last_month = expense_fixture(user, %{description: "Last month expense", date: last_month})
      expense_three_months_ago = expense_fixture(user, %{description: "Three months ago expense", date: three_months_ago})

      # Create expense for other user to ensure isolation
      _other_user_expense = expense_fixture(other_user, %{description: "Other user expense", date: today})

      %{
        user: user,
        other_user: other_user,
        expense_today: expense_today,
        expense_last_week: expense_last_week,
        expense_last_month: expense_last_month,
        expense_three_months_ago: expense_three_months_ago
      }
    end

    test "returns all user expenses when no filters applied", %{user: user} do
      expenses = Expenses.list_user_expenses(user.id)

      assert length(expenses) == 4
      # Should be ordered by date descending
      assert Enum.map(expenses, & &1.description) == [
        "Today expense",
        "Last week expense",
        "Last month expense",
        "Three months ago expense"
      ]
    end

    test "returns only user's expenses, not other users'", %{user: user, other_user: other_user} do
      user_expenses = Expenses.list_user_expenses(user.id)
      other_user_expenses = Expenses.list_user_expenses(other_user.id)

      assert length(user_expenses) == 4
      assert length(other_user_expenses) == 1
      assert hd(other_user_expenses).description == "Other user expense"
    end

    test "filters expenses from last week", %{user: user} do
      expenses = Expenses.list_user_expenses(user.id, %{period: "last_week"})

      assert length(expenses) == 2
      descriptions = Enum.map(expenses, & &1.description)
      assert "Today expense" in descriptions
      assert "Last week expense" in descriptions
      refute "Last month expense" in descriptions
      refute "Three months ago expense" in descriptions
    end

    test "filters expenses from last month", %{user: user} do
      expenses = Expenses.list_user_expenses(user.id, %{period: "last_month"})

      assert length(expenses) == 3
      descriptions = Enum.map(expenses, & &1.description)
      assert "Today expense" in descriptions
      assert "Last week expense" in descriptions
      assert "Last month expense" in descriptions
      refute "Three months ago expense" in descriptions
    end

    test "filters expenses from last 3 months", %{user: user} do
      expenses = Expenses.list_user_expenses(user.id, %{period: "last_3_months"})

      assert length(expenses) == 4
      descriptions = Enum.map(expenses, & &1.description)
      assert "Today expense" in descriptions
      assert "Last week expense" in descriptions
      assert "Last month expense" in descriptions
      assert "Three months ago expense" in descriptions
    end

    test "filters expenses by custom date range", %{user: user} do
      from_date = Date.add(Date.utc_today(), -25)
      to_date = Date.add(Date.utc_today(), -10)

      expenses = Expenses.list_user_expenses(user.id, %{from_date: from_date, to_date: to_date})

      assert length(expenses) == 1
      assert hd(expenses).description == "Last month expense"
    end

    test "filters expenses from a specific date onwards", %{user: user} do
      from_date = Date.add(Date.utc_today(), -25)

      expenses = Expenses.list_user_expenses(user.id, %{from_date: from_date})

      assert length(expenses) == 3
      descriptions = Enum.map(expenses, & &1.description)
      assert "Today expense" in descriptions
      assert "Last week expense" in descriptions
      assert "Last month expense" in descriptions
      refute "Three months ago expense" in descriptions
    end

    test "filters expenses up to a specific date", %{user: user} do
      to_date = Date.add(Date.utc_today(), -25)

      expenses = Expenses.list_user_expenses(user.id, %{to_date: to_date})

      assert length(expenses) == 1
      assert hd(expenses).description == "Three months ago expense"
    end

    test "returns empty list when no expenses match filter", %{user: user} do
      from_date = Date.add(Date.utc_today(), -200)
      to_date = Date.add(Date.utc_today(), -150)

      expenses = Expenses.list_user_expenses(user.id, %{from_date: from_date, to_date: to_date})

      assert expenses == []
    end

    test "ignores invalid period filter", %{user: user} do
      expenses = Expenses.list_user_expenses(user.id, %{period: "invalid_period"})

      # Should return all expenses when filter is invalid
      assert length(expenses) == 4
    end

    test "handles nil date values in filters", %{user: user} do
      expenses = Expenses.list_user_expenses(user.id, %{from_date: nil, to_date: nil})

      # Should return all expenses when dates are nil
      assert length(expenses) == 4
    end
  end
end
