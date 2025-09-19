defmodule ExpenseTrackerApiWeb.ExpenseControllerTest do
  use ExpenseTrackerApiWeb.ConnCase

  import ExpenseTrackerApi.AccountsFixtures
  import ExpenseTrackerApi.ExpensesFixtures

  @valid_expense_attrs %{
    amount: "100.50",
    description: "Test expense",
    category: "groceries",
    date: "2023-12-01"
  }

  @invalid_expense_attrs %{
    amount: "invalid",
    description: "",
    category: "invalid_category"
  }

  setup %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    %{conn: conn, user: user}
  end

  describe "GET /api/expenses" do
    test "lists all user expenses", %{conn: conn, user: user} do
      _expense1 = expense_fixture(user, %{"description" => "Expense 1"})
      _expense2 = expense_fixture(user, %{"description" => "Expense 2"})

      # Create expense for another user (should not appear)
      other_user = user_fixture()
      _other_expense = expense_fixture(other_user, %{"description" => "Other user expense"})

      conn = get(conn, ~p"/api/expenses")

      assert %{"data" => expenses} = json_response(conn, 200)
      assert length(expenses) == 2

      expense_descriptions = Enum.map(expenses, & &1["description"])
      assert "Expense 1" in expense_descriptions
      assert "Expense 2" in expense_descriptions
      refute "Other user expense" in expense_descriptions
    end

    test "filters expenses by period", %{conn: conn, user: user} do
      # Create expenses with different dates
      today = Date.utc_today()
      last_week = Date.add(today, -5)
      last_month = Date.add(today, -20)
      old_expense = Date.add(today, -100)

      expense_fixture(user, %{"description" => "Recent", "date" => today})
      expense_fixture(user, %{"description" => "Last week", "date" => last_week})
      expense_fixture(user, %{"description" => "Last month", "date" => last_month})
      expense_fixture(user, %{"description" => "Old", "date" => old_expense})

      # Test last_week filter
      conn = get(conn, ~p"/api/expenses?period=last_week")
      assert %{"data" => expenses} = json_response(conn, 200)
      descriptions = Enum.map(expenses, & &1["description"])
      assert "Recent" in descriptions
      assert "Last week" in descriptions
      refute "Old" in descriptions
    end

    test "filters expenses by date range", %{conn: conn, user: user} do
      expense_fixture(user, %{"description" => "In range", "date" => ~D[2023-12-15]})
      expense_fixture(user, %{"description" => "Out of range", "date" => ~D[2023-11-01]})

      conn = get(conn, ~p"/api/expenses?from_date=2023-12-01&to_date=2023-12-31")

      assert %{"data" => expenses} = json_response(conn, 200)
      descriptions = Enum.map(expenses, & &1["description"])
      assert "In range" in descriptions
      refute "Out of range" in descriptions
    end

    test "returns empty list when user has no expenses", %{conn: conn} do
      conn = get(conn, ~p"/api/expenses")

      assert %{"data" => []} = json_response(conn, 200)
    end

    test "requires authentication", %{conn: _conn} do
      conn = build_conn()
      conn = get(conn, ~p"/api/expenses")

      assert json_response(conn, 401)
    end
  end

  describe "POST /api/expenses" do
    test "creates expense with valid data", %{conn: conn} do
      conn = post(conn, ~p"/api/expenses", expense: @valid_expense_attrs)

      assert %{
               "data" => %{
                 "id" => id,
                 "amount" => "100.50",
                 "description" => "Test expense",
                 "category" => "groceries",
                 "date" => "2023-12-01"
               }
             } = json_response(conn, 201)

      assert is_integer(id)
    end

    test "returns error with invalid data", %{conn: conn} do
      conn = post(conn, ~p"/api/expenses", expense: @invalid_expense_attrs)

      assert %{
               "error" => %{
                 "message" => "Validation failed",
                 "details" => details
               }
             } = json_response(conn, 422)

      assert Map.has_key?(details, "amount")
      assert Map.has_key?(details, "description")
    end

    test "requires authentication", %{conn: _conn} do
      conn = build_conn()
      conn = post(conn, ~p"/api/expenses", expense: @valid_expense_attrs)

      assert json_response(conn, 401)
    end
  end

  describe "GET /api/expenses/:id" do
    test "shows expense when it belongs to user", %{conn: conn, user: user} do
      expense = expense_fixture(user)

      conn = get(conn, ~p"/api/expenses/#{expense.id}")

      assert %{
               "data" => %{
                 "id" => id,
                 "amount" => amount,
                 "description" => description,
                 "category" => category
               }
             } = json_response(conn, 200)

      assert id == expense.id
      assert amount == to_string(expense.amount)
      assert description == expense.description
      assert category == to_string(expense.category)
    end

    test "returns 404 when expense doesn't exist", %{conn: conn} do
      conn = get(conn, ~p"/api/expenses/999999")

      assert %{
               "error" => %{
                 "message" => "Expense not found"
               }
             } = json_response(conn, 404)
    end

    test "returns 404 when expense belongs to another user", %{conn: conn} do
      other_user = user_fixture()
      expense = expense_fixture(other_user)

      conn = get(conn, ~p"/api/expenses/#{expense.id}")

      assert %{
               "error" => %{
                 "message" => "Expense not found"
               }
             } = json_response(conn, 404)
    end

    test "requires authentication", %{conn: _conn, user: user} do
      expense = expense_fixture(user)
      conn = build_conn()
      conn = get(conn, ~p"/api/expenses/#{expense.id}")

      assert json_response(conn, 401)
    end
  end

  describe "PUT /api/expenses/:id" do
    test "updates expense with valid data", %{conn: conn, user: user} do
      expense = expense_fixture(user)
      update_attrs = %{description: "Updated expense", amount: "200.00"}

      conn = put(conn, ~p"/api/expenses/#{expense.id}", expense: update_attrs)

      assert %{
               "data" => %{
                 "id" => id,
                 "description" => "Updated expense",
                 "amount" => "200.00"
               }
             } = json_response(conn, 200)

      assert id == expense.id
    end

    test "returns error with invalid data", %{conn: conn, user: user} do
      expense = expense_fixture(user)

      conn = put(conn, ~p"/api/expenses/#{expense.id}", expense: @invalid_expense_attrs)

      assert %{
               "error" => %{
                 "message" => "Validation failed",
                 "details" => _details
               }
             } = json_response(conn, 422)
    end

    test "returns 404 when expense doesn't exist", %{conn: conn} do
      conn = put(conn, ~p"/api/expenses/999999", expense: %{description: "Updated"})

      assert %{
               "error" => %{
                 "message" => "Expense not found"
               }
             } = json_response(conn, 404)
    end

    test "returns 404 when expense belongs to another user", %{conn: conn} do
      other_user = user_fixture()
      expense = expense_fixture(other_user)

      conn = put(conn, ~p"/api/expenses/#{expense.id}", expense: %{description: "Updated"})

      assert %{
               "error" => %{
                 "message" => "Expense not found"
               }
             } = json_response(conn, 404)
    end

    test "requires authentication", %{conn: _conn, user: user} do
      expense = expense_fixture(user)
      conn = build_conn()
      conn = put(conn, ~p"/api/expenses/#{expense.id}", expense: %{description: "Updated"})

      assert json_response(conn, 401)
    end
  end

  describe "DELETE /api/expenses/:id" do
    test "deletes expense when it belongs to user", %{conn: conn, user: user} do
      expense = expense_fixture(user)

      conn = delete(conn, ~p"/api/expenses/#{expense.id}")

      assert %{
               "data" => %{
                 "message" => "Expense deleted successfully"
               }
             } = json_response(conn, 200)

      # Verify expense is actually deleted
      assert_raise Ecto.NoResultsError, fn ->
        ExpenseTrackerApi.Expenses.get_user_expense!(user.id, expense.id)
      end
    end

    test "returns 404 when expense doesn't exist", %{conn: conn} do
      conn = delete(conn, ~p"/api/expenses/999999")

      assert %{
               "error" => %{
                 "message" => "Expense not found"
               }
             } = json_response(conn, 404)
    end

    test "returns 404 when expense belongs to another user", %{conn: conn} do
      other_user = user_fixture()
      expense = expense_fixture(other_user)

      conn = delete(conn, ~p"/api/expenses/#{expense.id}")

      assert %{
               "error" => %{
                 "message" => "Expense not found"
               }
             } = json_response(conn, 404)
    end

    test "requires authentication", %{conn: _conn, user: user} do
      expense = expense_fixture(user)
      conn = build_conn()
      conn = delete(conn, ~p"/api/expenses/#{expense.id}")

      assert json_response(conn, 401)
    end
  end

  describe "CORS configuration for authenticated endpoints" do
    test "includes CORS headers in authenticated requests", %{conn: conn, user: user} do
      _expense = expense_fixture(user)

      conn =
        conn
        |> put_req_header("origin", "http://localhost:3000")
        |> get(~p"/api/expenses")

      # Check that CORS headers are present even for authenticated endpoints
      assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:3000"]
      assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]
      assert json_response(conn, 200)
    end
  end
end
