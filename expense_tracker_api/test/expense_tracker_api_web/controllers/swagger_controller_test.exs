defmodule ExpenseTrackerApiWeb.SwaggerControllerTest do
  use ExpenseTrackerApiWeb.ConnCase, async: false

  describe "GET /api/docs" do
    test "renders Swagger UI when documentation is enabled in development", %{conn: conn} do
      # In test environment, docs should be enabled by default
      conn = get(conn, ~p"/api/docs")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]

      response_body = response(conn, 200)

      # Verify Swagger UI HTML structure
      assert response_body =~ "Expense Tracker API Documentation"
      assert response_body =~ "swagger-ui-bundle.js"
      assert response_body =~ "swagger-ui-dist"
      assert response_body =~ "#swagger-ui"

      # Verify OpenAPI spec URL is configured
      assert response_body =~ "/api/openapi"

      # Verify JWT authorization configuration
      assert response_body =~ "Authorization"
      assert response_body =~ "Bearer"
      assert response_body =~ "JWT Authentication Quick Start"
    end
  end

  describe "GET /api/openapi" do
    test "returns OpenAPI specification when documentation is enabled", %{conn: conn} do
      conn = get(conn, ~p"/api/openapi")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      spec = json_response(conn, 200)

      # Verify OpenAPI specification structure
      assert spec["openapi"] == "3.0.0"
      assert spec["info"]["title"] == "Expense Tracker API"
      assert spec["info"]["version"] == "1.0.0"

      # Verify JWT security scheme is configured
      assert spec["components"]["securitySchemes"]["bearerAuth"]["type"] == "http"
      assert spec["components"]["securitySchemes"]["bearerAuth"]["scheme"] == "bearer"
      assert spec["components"]["securitySchemes"]["bearerAuth"]["bearerFormat"] == "JWT"

      # Verify paths are included
      assert Map.has_key?(spec, "paths")
      assert is_map(spec["paths"])
    end
  end

  describe "JWT Authentication Integration" do
    test "OpenAPI spec includes security requirements for protected endpoints", %{conn: conn} do
      conn = get(conn, ~p"/api/openapi")
      spec = json_response(conn, 200)

      # Check that expense endpoints have security requirements
      expense_paths = spec["paths"]

      # Verify GET /api/expenses has security requirement
      if Map.has_key?(expense_paths, "/api/expenses") do
        get_expenses = expense_paths["/api/expenses"]["get"]
        assert is_list(get_expenses["security"])
        assert Enum.any?(get_expenses["security"], fn security_req ->
          Map.has_key?(security_req, "bearerAuth")
        end)
      end

      # Verify POST /api/expenses has security requirement
      if Map.has_key?(expense_paths, "/api/expenses") do
        post_expenses = expense_paths["/api/expenses"]["post"]
        assert is_list(post_expenses["security"])
        assert Enum.any?(post_expenses["security"], fn security_req ->
          Map.has_key?(security_req, "bearerAuth")
        end)
      end
    end

    test "auth endpoints are documented without security requirements", %{conn: conn} do
      conn = get(conn, ~p"/api/openapi")
      spec = json_response(conn, 200)

      expense_paths = spec["paths"]

      # Verify POST /api/auth/login does not require authentication
      if Map.has_key?(expense_paths, "/api/auth/login") do
        login_endpoint = expense_paths["/api/auth/login"]["post"]
        # Login should not have security requirements or should be empty
        security = Map.get(login_endpoint, "security", [])
        assert security == [] or is_nil(security)
      end

      # Verify POST /api/auth/register does not require authentication
      if Map.has_key?(expense_paths, "/api/auth/register") do
        register_endpoint = expense_paths["/api/auth/register"]["post"]
        # Register should not have security requirements or should be empty
        security = Map.get(register_endpoint, "security", [])
        assert security == [] or is_nil(security)
      end
    end
  end

  describe "Swagger UI JWT Integration" do
    test "Swagger UI HTML includes JWT authorization configuration", %{conn: conn} do
      conn = get(conn, ~p"/api/docs")
      response_body = response(conn, 200)

      # Verify JWT-specific configuration in the HTML
      assert response_body =~ "requestInterceptor"
      assert response_body =~ "responseInterceptor"
      assert response_body =~ "Authorization"
      assert response_body =~ "Bearer"

      # Verify the request interceptor handles JWT token format
      assert response_body =~ "request.headers.Authorization"
      assert response_body =~ "startsWith('Bearer ')"

      # Verify enhanced JWT helper UI
      assert response_body =~ "JWT Authentication Quick Start"
      assert response_body =~ "copyToken"
      assert response_body =~ "displayToken"
    end

    test "Swagger UI includes proper OpenAPI spec URL", %{conn: conn} do
      conn = get(conn, ~p"/api/docs")
      response_body = response(conn, 200)

      # Verify the spec URL is dynamically generated
      expected_spec_url = "#{conn.scheme}://#{conn.host}:#{conn.port}/api/openapi"
      assert response_body =~ expected_spec_url
    end
  end

  describe "JWT Workflow Integration Test" do
    test "complete JWT authentication workflow through Swagger endpoints", %{conn: conn} do
      # Step 1: Get OpenAPI spec
      conn = get(conn, ~p"/api/openapi")
      spec = json_response(conn, 200)

      # Step 2: Verify login endpoint is documented
      login_path = spec["paths"]["/api/auth/login"]
      assert login_path != nil
      assert login_path["post"] != nil

      # Step 3: Verify login response includes JWT token schema
      login_responses = login_path["post"]["responses"]
      success_response = login_responses["200"]
      assert success_response != nil

      # Step 4: Verify protected endpoints require bearerAuth
      if Map.has_key?(spec["paths"], "/api/expenses") do
        expenses_get = spec["paths"]["/api/expenses"]["get"]
        assert Enum.any?(expenses_get["security"], fn sec ->
          Map.has_key?(sec, "bearerAuth")
        end)
      end

      # Step 5: Verify Swagger UI can be loaded
      conn = build_conn() |> get(~p"/api/docs")
      assert response(conn, 200)
      response_body = response(conn, 200)

      # Step 6: Verify Swagger UI has authorization capabilities
      assert response_body =~ "requestInterceptor"
      assert response_body =~ "responseInterceptor"
      assert response_body =~ "JWT Authentication Quick Start"
    end
  end

  describe "Enhanced JWT User Experience" do
    test "Swagger UI provides clear JWT authentication instructions", %{conn: conn} do
      conn = get(conn, ~p"/api/openapi")
      spec = json_response(conn, 200)

      # Verify API description includes authentication instructions
      api_description = spec["info"]["description"]
      assert api_description =~ "JWT"
      assert api_description =~ "Authentication"
      assert api_description =~ "Bearer"
      assert api_description =~ "login"

      # Verify security scheme has helpful description
      bearer_auth = spec["components"]["securitySchemes"]["bearerAuth"]
      assert bearer_auth["description"] =~ "JWT token obtained from login endpoint"
    end

    test "login endpoint response schema includes token field", %{conn: conn} do
      conn = get(conn, ~p"/api/openapi")
      spec = json_response(conn, 200)

      # Check if login endpoint exists and has proper response schema
      if Map.has_key?(spec["paths"], "/api/auth/login") do
        login_responses = spec["paths"]["/api/auth/login"]["post"]["responses"]
        success_response = login_responses["200"]

        # The response should reference a schema that includes token
        assert success_response != nil
        assert Map.has_key?(success_response, "content")
      end
    end
  end
end
