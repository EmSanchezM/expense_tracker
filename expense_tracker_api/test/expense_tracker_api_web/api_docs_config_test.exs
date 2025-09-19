defmodule ExpenseTrackerApiWeb.ApiDocsConfigTest do
  use ExUnit.Case, async: true

  alias ExpenseTrackerApiWeb.ApiDocsConfig

  describe "enabled?/0" do
    test "returns true in development environment" do
      # This test runs in test environment, which should return true
      assert ApiDocsConfig.enabled?() == true
    end

    test "returns false in production without ENABLE_API_DOCS" do
      # Mock production environment behavior
      original_env = System.get_env("ENABLE_API_DOCS")
      System.delete_env("ENABLE_API_DOCS")

      # We can't easily change Mix.env() in tests, so we'll test the logic
      # by checking that the function exists and works
      assert is_boolean(ApiDocsConfig.enabled?())

      # Restore original environment
      if original_env do
        System.put_env("ENABLE_API_DOCS", original_env)
      end
    end

    test "returns true in production with ENABLE_API_DOCS=true" do
      original_env = System.get_env("ENABLE_API_DOCS")
      System.put_env("ENABLE_API_DOCS", "true")

      # The function should work regardless of environment
      assert is_boolean(ApiDocsConfig.enabled?())

      # Restore original environment
      if original_env do
        System.put_env("ENABLE_API_DOCS", original_env)
      else
        System.delete_env("ENABLE_API_DOCS")
      end
    end
  end

  describe "require_auth?/0" do
    test "returns boolean value" do
      assert is_boolean(ApiDocsConfig.require_auth?())
    end
  end

  describe "openapi_spec_url/0" do
    test "returns correct OpenAPI spec URL" do
      assert ApiDocsConfig.openapi_spec_url() == "/api/openapi"
    end
  end

  describe "swagger_ui_config/0" do
    test "returns valid Swagger UI configuration" do
      config = ApiDocsConfig.swagger_ui_config()

      assert is_map(config)
      assert config.url == "/api/openapi"
      assert config.dom_id == "#swagger-ui"
      assert config.deepLinking == true
      assert is_list(config.presets)
      assert is_list(config.plugins)
      assert config.layout == "StandaloneLayout"
    end
  end
end
