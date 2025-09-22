defmodule ExpenseTrackerApiWeb.JwtSwaggerIntegrationTest do
  use ExpenseTrackerApiWeb.ConnCase, async: false

  alias ExpenseTrackerApi.Accounts

  describe "JWT Swagger Integration End-to-End" do
    setup do
      # Create a test user
      user_attrs = %{
        name: "Test User",
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      }

      {:ok, user} = Accounts.create_user(user_attrs)

      %{user: user, user_attrs: user_attrs}
    end

    test "complete workflow: login -> get token -> use in protected endpoint", %{conn: conn, user_attrs: user_attrs} do
      # Step 1: Verify Swagger UI loads with JWT helper
      swagger_conn = get(conn, ~p"/api/docs")
      assert response(swagger_conn, 200)
      swagger_html = response(swagger_conn, 200)

      # Verify JWT helper is present
      assert swagger_html =~ "JWT Authentication Quick Start"
      assert swagger_html =~ "POST /api/auth/login"
      assert swagger_html =~ "responseInterceptor"
      assert swagger_html =~ "displayToken"

      # Step 2: Login to get JWT token (simulating what user would do in Swagger)
      login_conn = post(conn, ~p"/api/auth/login", %{
        "email" => user_attrs.email,
        "password" => user_attrs.password
      })

      assert response(login_conn, 200)
      login_response = json_response(login_conn, 200)
      assert Map.has_key?(login_response, "data")
      assert Map.has_key?(login_response["data"], "token")
      jwt_token = login_response["data"]["token"]

      # Step 3: Verify OpenAPI spec shows protected endpoints require authentication
      spec_conn = get(conn, ~p"/api/openapi")
      spec = json_response(spec_conn, 200)

      # Check that expense endpoints require bearerAuth
      if Map.has_key?(spec["paths"], "/api/expenses") do
        expenses_endpoint = spec["paths"]["/api/expenses"]["get"]
        assert is_list(expenses_endpoint["security"])
        assert Enum.any?(expenses_endpoint["security"], fn sec ->
          Map.has_key?(sec, "bearerAuth")
        end)
      end

      # Step 4: Use JWT token to access protected endpoint (simulating Swagger UI request)
      protected_conn = conn
      |> put_req_header("authorization", "Bearer #{jwt_token}")
      |> get(~p"/api/expenses")

      assert response(protected_conn, 200)
      expenses_response = json_response(protected_conn, 200)
      assert Map.has_key?(expenses_response, "data")
      assert is_list(expenses_response["data"])

      # Step 5: Verify that without token, the endpoint is protected
      unauth_conn = get(conn, ~p"/api/expenses")
      assert response(unauth_conn, 401)
    end

    test "Swagger UI responseInterceptor would capture JWT token from login", %{conn: conn} do
      # This test verifies the JavaScript logic that would run in the browser

      # Get the Swagger UI HTML
      swagger_conn = get(conn, ~p"/api/docs")
      swagger_html = response(swagger_conn, 200)

      # Verify the responseInterceptor logic is present
      assert swagger_html =~ "responseInterceptor: function(response)"
      assert swagger_html =~ "response.url.includes('/api/auth/login')"
      assert swagger_html =~ "response.status === 200"
      assert swagger_html =~ "responseData.token"
      assert swagger_html =~ "displayToken(responseData.token)"

      # Verify the token display functionality
      assert swagger_html =~ "function displayToken(token)"
      assert swagger_html =~ "lastJwtToken = token"
      assert swagger_html =~ "token-display"
      assert swagger_html =~ "Copy Token"

      # Verify the copy functionality
      assert swagger_html =~ "function copyToken()"
      assert swagger_html =~ "navigator.clipboard.writeText(lastJwtToken)"
    end

    test "OpenAPI spec provides clear authentication documentation", %{conn: conn} do
      spec_conn = get(conn, ~p"/api/openapi")
      spec = json_response(spec_conn, 200)

      # Verify API description includes authentication instructions
      api_description = spec["info"]["description"]
      assert api_description =~ "JWT"
      assert api_description =~ "Authentication"
      assert api_description =~ "Bearer"
      assert api_description =~ "login"
      assert api_description =~ "registration"

      # Verify security scheme documentation
      bearer_auth = spec["components"]["securitySchemes"]["bearerAuth"]
      assert bearer_auth["type"] == "http"
      assert bearer_auth["scheme"] == "bearer"
      assert bearer_auth["bearerFormat"] == "JWT"
      assert bearer_auth["description"] =~ "JWT token obtained from login endpoint"

      # Verify login endpoint is documented and accessible
      login_endpoint = spec["paths"]["/api/auth/login"]["post"]
      assert login_endpoint != nil
      assert login_endpoint["summary"] != nil

      # Verify login response schema indicates token will be returned
      login_responses = login_endpoint["responses"]["200"]
      assert login_responses != nil
    end

    test "JWT workflow provides excellent developer experience", %{conn: conn, user_attrs: user_attrs} do
      # This test verifies the complete developer experience

      # 1. Developer opens Swagger UI
      swagger_conn = get(conn, ~p"/api/docs")
      swagger_html = response(swagger_conn, 200)

      # They see clear instructions
      assert swagger_html =~ "🔐 JWT Authentication Quick Start"
      assert swagger_html =~ "First, use the"
      assert swagger_html =~ "POST /api/auth/login"
      assert swagger_html =~ "Copy the token from the response"
      assert swagger_html =~ "Authorize"
      assert swagger_html =~ "Now you can test all protected endpoints! 🎉"

      # 2. They can see the OpenAPI spec with clear documentation
      spec_conn = get(conn, ~p"/api/openapi")
      spec = json_response(spec_conn, 200)

      # Clear API description
      assert spec["info"]["description"] =~ "Authentication"
      assert spec["info"]["description"] =~ "JWT"

      # 3. They perform login and get a token
      login_conn = post(conn, ~p"/api/auth/login", %{
        "email" => user_attrs.email,
        "password" => user_attrs.password
      })

      login_response = json_response(login_conn, 200)
      jwt_token = login_response["data"]["token"]

      # 4. They can use the token successfully
      protected_conn = conn
      |> put_req_header("authorization", "Bearer #{jwt_token}")
      |> get(~p"/api/expenses")

      assert response(protected_conn, 200)

      # 5. The Swagger UI would automatically capture and display the token
      # (This is verified by the presence of the JavaScript code)
      assert swagger_html =~ "🎉 JWT Token received! Check the helper box above to copy it."
    end
  end
end
