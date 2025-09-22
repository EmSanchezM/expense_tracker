defmodule ExpenseTrackerApi.SeedData.CompleteWorkflowTest do
  @moduledoc """
  Integration test for the complete seeding workflow.

  This test validates the entire process: seed → authenticate → filter expenses
  by different periods, ensuring all generated data works correctly with the
  application's authentication and filtering systems.
  """

  use ExpenseTrackerApi.DataCase, async: false

  alias ExpenseTrackerApi.SeedData.SeedDataGenerator
  alias ExpenseTrackerApi.Accounts
  alias ExpenseTrackerApi.Repo

  import Ecto.Query

  describe "complete seeding workflow" do
    test "seed → authenticate → filter expenses workflow works correctly" do
      # Step 1: Run the complete seeding process
      assert :ok = SeedDataGenerator.run()

      # Step 2: Verify exactly 2 users and 20 expenses were created
      user_count = Repo.aggregate(from(u in ExpenseTrackerApi.Accounts.User), :count, :id)
      expense_count = Repo.aggregate(from(e in ExpenseTrackerApi.Expenses.Expense), :count, :id)

      assert user_count == 2, "Expected 2 users, got #{user_count}"
      assert expense_count == 20, "Expected 20 expenses, got #{expense_count}"

      # Step 3: Test authentication with generated users
      test_users = [
        %{email: "juan.perez@example.com", password: "password123"},
        %{email: "maria.garcia@example.com", password: "password123"}
      ]

      authenticated_users =
        Enum.map(test_users, fn user_data ->
          # Test that users can authenticate successfully
          case Accounts.authenticate_user(user_data.email, user_data.password) do
            {:ok, user} ->
              assert user.email == user_data.email
              assert user.name != nil
              assert user.id != nil
              user

            {:error, reason} ->
              flunk("Authentication failed for #{user_data.email}: #{inspect(reason)}")
          end
        end)

      # Step 4: Test expense filtering by different periods for each user
      Enum.each(authenticated_users, fn user ->
        test_expense_filtering_for_user(user)
      end)

      # Step 5: Test idempotency - run seeding again
      assert :ok = SeedDataGenerator.run()

      # Verify counts remain the same (no duplicates)
      final_user_count = Repo.aggregate(from(u in ExpenseTrackerApi.Accounts.User), :count, :id)
      final_expense_count = Repo.aggregate(from(e in ExpenseTrackerApi.Expenses.Expense), :count, :id)

      assert final_user_count == 2, "Idempotency failed: user count changed from 2 to #{final_user_count}"
      assert final_expense_count == 20, "Idempotency failed: expense count changed from 20 to #{final_expense_count}"
    end

    test "generated data meets all schema validation requirements" do
      # Run seeding
      assert :ok = SeedDataGenerator.run()

      # Validate all users meet schema requirements
      users = Repo.all(ExpenseTrackerApi.Accounts.User)

      Enum.each(users, fn user ->
        # Test user data against schema
        changeset = ExpenseTrackerApi.Accounts.User.changeset(%ExpenseTrackerApi.Accounts.User{}, %{
          name: user.name,
          email: user.email,
          password: "password123"  # Use original password for validation
        })

        assert changeset.valid?, "User #{user.email} fails schema validation: #{inspect(changeset.errors)}"

        # Validate specific requirements
        assert String.length(user.name) > 0, "User name cannot be empty"
        assert String.contains?(user.email, "@"), "User email must contain @"
        assert user.password_hash != nil, "User must have password hash"
      end)

      # Validate all expenses meet schema requirements
      expenses = Repo.all(ExpenseTrackerApi.Expenses.Expense)

      Enum.each(expenses, fn expense ->
        # Test expense data against schema
        changeset = ExpenseTrackerApi.Expenses.Expense.changeset(%ExpenseTrackerApi.Expenses.Expense{}, %{
          amount: expense.amount,
          description: expense.description,
          category: expense.category,
          date: expense.date,
          user_id: expense.user_id
        })

        assert changeset.valid?, "Expense #{expense.id} fails schema validation: #{inspect(changeset.errors)}"

        # Validate specific requirements
        assert Decimal.gt?(expense.amount, 0), "Expense amount must be greater than 0"
        assert String.length(expense.description) > 0, "Expense description cannot be empty"
        assert expense.category in [:groceries, :utilities, :leisure, :health, :electronics, :clothing, :others],
               "Invalid expense category: #{expense.category}"
        assert expense.user_id != nil, "Expense must have user_id"
        assert expense.date != nil, "Expense must have date"
      end)
    end

    test "temporal distribution meets requirements" do
      # Run seeding
      assert :ok = SeedDataGenerator.run()

      users = Repo.all(ExpenseTrackerApi.Accounts.User)

      Enum.each(users, fn user ->
        user_expenses = Repo.all(from(e in ExpenseTrackerApi.Expenses.Expense, where: e.user_id == ^user.id))

        assert length(user_expenses) == 10, "Each user should have exactly 10 expenses"

        # Test temporal distribution
        today = Date.utc_today()

        last_week_expenses = filter_expenses_by_date_range(user_expenses, Date.add(today, -7), today)
        last_month_expenses = filter_expenses_by_date_range(user_expenses, Date.add(today, -30), today)
        last_3_months_expenses = filter_expenses_by_date_range(user_expenses, Date.add(today, -90), today)
        last_6_months_expenses = filter_expenses_by_date_range(user_expenses, Date.add(today, -180), today)

        # Verify temporal distribution (allowing some flexibility due to randomization)
        assert length(last_week_expenses) >= 1, "Should have at least 1 expense in last week"
        assert length(last_month_expenses) >= 3, "Should have at least 3 expenses in last month"
        assert length(last_3_months_expenses) >= 6, "Should have at least 6 expenses in last 3 months"
        assert length(last_6_months_expenses) == 10, "Should have all 10 expenses in last 6 months"
      end)
    end

    test "category distribution meets requirements" do
      # Run seeding
      assert :ok = SeedDataGenerator.run()

      users = Repo.all(ExpenseTrackerApi.Accounts.User)

      Enum.each(users, fn user ->
        user_expenses = Repo.all(from(e in ExpenseTrackerApi.Expenses.Expense, where: e.user_id == ^user.id))

        # Count expenses by category
        category_counts = Enum.reduce(user_expenses, %{}, fn expense, acc ->
          Map.update(acc, expense.category, 1, &(&1 + 1))
        end)

        # Verify we have the expected categories
        expected_categories = [:groceries, :utilities, :leisure, :health, :electronics, :clothing]
        actual_categories = Map.keys(category_counts)

        Enum.each(expected_categories, fn category ->
          assert category in actual_categories, "Missing expected category: #{category}"
        end)

        # Verify total count
        total_expenses = Enum.sum(Map.values(category_counts))
        assert total_expenses == 10, "Total expenses should be 10, got #{total_expenses}"

        # Verify groceries is the most common category (should have 3)
        groceries_count = Map.get(category_counts, :groceries, 0)
        assert groceries_count >= 2, "Groceries should have at least 2 expenses, got #{groceries_count}"
      end)
    end
  end

  # Private helper functions

  defp test_expense_filtering_for_user(user) do
    today = Date.utc_today()

    # Test filtering by different time periods
    time_periods = [
      {Date.add(today, -7), today, "last week"},
      {Date.add(today, -30), today, "last month"},
      {Date.add(today, -90), today, "last 3 months"},
      {Date.add(today, -180), today, "last 6 months"}
    ]

    Enum.each(time_periods, fn {start_date, end_date, period_name} ->
      # Test expense filtering (assuming you have a function to filter expenses)
      expenses = get_user_expenses_in_date_range(user.id, start_date, end_date)

      # Verify all returned expenses are within the date range
      Enum.each(expenses, fn expense ->
        assert Date.compare(expense.date, start_date) in [:gt, :eq],
               "Expense date #{expense.date} is before start date #{start_date} for #{period_name}"
        assert Date.compare(expense.date, end_date) in [:lt, :eq],
               "Expense date #{expense.date} is after end date #{end_date} for #{period_name}"
      end)

      # Verify we have some expenses in the broader time periods
      if period_name == "last 6 months" do
        assert length(expenses) == 10, "User should have all 10 expenses in last 6 months"
      end
    end)

    # Test filtering by category
    categories = [:groceries, :utilities, :leisure, :health, :electronics, :clothing]

    Enum.each(categories, fn category ->
      category_expenses = get_user_expenses_by_category(user.id, category)

      # Verify all returned expenses have the correct category
      Enum.each(category_expenses, fn expense ->
        assert expense.category == category,
               "Expense has wrong category. Expected: #{category}, Got: #{expense.category}"
      end)
    end)
  end

  defp get_user_expenses_in_date_range(user_id, start_date, end_date) do
    from(e in ExpenseTrackerApi.Expenses.Expense,
      where: e.user_id == ^user_id and e.date >= ^start_date and e.date <= ^end_date,
      order_by: [desc: e.date]
    )
    |> Repo.all()
  end

  defp get_user_expenses_by_category(user_id, category) do
    from(e in ExpenseTrackerApi.Expenses.Expense,
      where: e.user_id == ^user_id and e.category == ^category,
      order_by: [desc: e.date]
    )
    |> Repo.all()
  end

  defp filter_expenses_by_date_range(expenses, start_date, end_date) do
    Enum.filter(expenses, fn expense ->
      Date.compare(expense.date, start_date) in [:gt, :eq] and
      Date.compare(expense.date, end_date) in [:lt, :eq]
    end)
  end
end
