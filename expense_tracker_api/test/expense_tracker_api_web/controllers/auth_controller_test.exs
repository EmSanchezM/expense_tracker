defmodule ExpenseTrackerApiWeb.AuthControllerTest do
  use ExpenseTrackerApiWeb.ConnCase

  import ExpenseTrackerApi.AccountsFixtures

  @valid_user_attrs %{
    email: "test@example.com",
    password: "password123",
    name: "Test User"
  }

  @invalid_user_attrs %{
    email: "invalid-email",
    password: "123",
    name: ""
  }

  describe "POST /api/auth/register" do
    test "creates user with valid data", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/register", user: @valid_user_attrs)

      assert %{
               "data" => %{
                 "id" => id,
                 "email" => "test@example.com",
                 "name" => "Test User"
               }
             } = json_response(conn, 201)

      assert is_integer(id)
    end

    test "returns error with invalid data", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/register", user: @invalid_user_attrs)

      assert %{
               "error" => %{
                 "message" => "Validation failed",
                 "details" => details
               }
             } = json_response(conn, 422)

      assert Map.has_key?(details, "email")
      assert Map.has_key?(details, "password")
      assert Map.has_key?(details, "name")
    end

    test "returns error when email already exists", %{conn: conn} do
      user_fixture(%{email: "test@example.com"})

      conn = post(conn, ~p"/api/auth/register", user: @valid_user_attrs)

      assert %{
               "error" => %{
                 "message" => "Validation failed",
                 "details" => %{"email" => _}
               }
             } = json_response(conn, 422)
    end

    test "does not return password in response", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/register", user: @valid_user_attrs)

      response = json_response(conn, 201)
      refute Map.has_key?(response["data"], "password")
      refute Map.has_key?(response["data"], "password_hash")
    end
  end

  describe "POST /api/auth/login" do
    setup do
      user = user_fixture(%{email: "test@example.com", password: "password123"})
      %{user: user}
    end

    test "returns JWT token with valid credentials", %{conn: conn, user: user} do
      conn = post(conn, ~p"/api/auth/login", %{
        email: user.email,
        password: "password123"
      })

      assert %{
               "data" => %{
                 "token" => token,
                 "user" => %{
                   "id" => id,
                   "email" => "test@example.com",
                   "name" => name
                 }
               }
             } = json_response(conn, 200)

      assert is_binary(token)
      assert token != ""
      assert id == user.id
      assert is_binary(name)
    end

    test "returns error with invalid email", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/login", %{
        email: "wrong@example.com",
        password: "password123"
      })

      assert %{
               "error" => %{
                 "message" => "Invalid credentials"
               }
             } = json_response(conn, 401)
    end

    test "returns error with invalid password", %{conn: conn, user: user} do
      conn = post(conn, ~p"/api/auth/login", %{
        email: user.email,
        password: "wrongpassword"
      })

      assert %{
               "error" => %{
                 "message" => "Invalid credentials"
               }
             } = json_response(conn, 401)
    end

    test "returns error when email is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/login", %{password: "password123"})

      assert %{
               "error" => %{
                 "message" => "Email and password are required"
               }
             } = json_response(conn, 400)
    end

    test "returns error when password is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/login", %{email: "test@example.com"})

      assert %{
               "error" => %{
                 "message" => "Email and password are required"
               }
             } = json_response(conn, 400)
    end

    test "does not return password in response", %{conn: conn, user: user} do
      conn = post(conn, ~p"/api/auth/login", %{
        email: user.email,
        password: "password123"
      })

      response = json_response(conn, 200)
      refute Map.has_key?(response["data"]["user"], "password")
      refute Map.has_key?(response["data"]["user"], "password_hash")
    end
  end

  describe "CORS configuration" do
    test "includes CORS headers in response", %{conn: conn} do
      conn =
        conn
        |> put_req_header("origin", "http://localhost:3000")
        |> post(~p"/api/auth/register", user: @valid_user_attrs)

      # Check that CORS headers are present
      assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:3000"]
      assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]
    end

    test "supports multiple allowed origins", %{conn: conn} do
      # Test with localhost:5173 (Vite default)
      conn =
        conn
        |> put_req_header("origin", "http://localhost:5173")
        |> post(~p"/api/auth/register", user: @valid_user_attrs)

      assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:5173"]
      assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]
    end

    test "allows JWT authorization header", %{conn: conn} do
      conn =
        conn
        |> put_req_header("origin", "http://localhost:3000")
        |> put_req_header("authorization", "Bearer fake-jwt-token")
        |> post(~p"/api/auth/register", user: @valid_user_attrs)

      # Should not fail due to CORS and should include CORS headers
      assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:3000"]
      assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]
    end
  end
end
