defmodule ExpenseTrackerApiWeb.ApiDocsConfig do
  @moduledoc """
  Configuration module for API documentation features.

  Controls when API documentation endpoints are available based on environment
  and configuration settings.
  """

  @doc """
  Determines if API documentation should be enabled.

  In development and test environments, documentation is enabled by default.
  In production, documentation is disabled unless explicitly enabled via
  the ENABLE_API_DOCS environment variable.
  """
  def enabled? do
    case Mix.env() do
      :prod -> System.get_env("ENABLE_API_DOCS") == "true"
      _ -> true
    end
  end

  @doc """
  Determines if authentication should be required for accessing documentation.

  Currently returns true for production environment, false otherwise.
  This can be extended in the future to support authentication-protected
  documentation access.
  """
  def require_auth? do
    Mix.env() == :prod
  end

  @doc """
  Returns the base URL for the OpenAPI specification.

  This is used by Swagger UI to load the API specification.
  """
  def openapi_spec_url do
    "/api/openapi"
  end

  @doc """
  Returns configuration for Swagger UI.

  Includes settings for JWT authorization and other UI preferences.
  """
  def swagger_ui_config do
    %{
      url: openapi_spec_url(),
      dom_id: "#swagger-ui",
      deepLinking: true,
      presets: [
        "SwaggerUIBundle.presets.apis",
        "SwaggerUIStandalonePreset"
      ],
      plugins: [
        "SwaggerUIBundle.plugins.DownloadUrl"
      ],
      layout: "StandaloneLayout"
    }
  end
end
