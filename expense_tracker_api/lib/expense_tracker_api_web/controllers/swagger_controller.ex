defmodule ExpenseTrackerApiWeb.SwaggerController do
  use ExpenseTrackerApiWeb, :controller

  alias ExpenseTrackerApiWeb.ApiDocsConfig

  @moduledoc """
  Controller for serving Swagger UI documentation interface.

  Provides an interactive documentation interface for the API using Swagger UI.
  Access is controlled based on environment configuration.
  """

  @doc """
  Serves the Swagger UI interface for API documentation.

  The interface allows developers to:
  - Browse all available API endpoints
  - View request/response schemas and examples
  - Test endpoints directly with JWT authentication
  - Understand API structure and requirements

  Access is controlled by environment-based configuration.
  """
  def index(conn, _params) do
    if ApiDocsConfig.enabled? do
      render_swagger_ui(conn)
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "API documentation not available"})
    end
  end

  @doc """
  Returns the OpenAPI specification as JSON.

  This endpoint provides the raw OpenAPI 3.0 specification that describes
  all API endpoints, schemas, and authentication requirements.
  """
  def spec(conn, _params) do
    if ApiDocsConfig.enabled? do
      spec = ExpenseTrackerApiWeb.ApiSpec.spec()
      json(conn, spec)
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "API documentation not available"})
    end
  end

  defp render_swagger_ui(conn) do
    # Get the base URL for the OpenAPI spec
    base_url = "#{conn.scheme}://#{conn.host}:#{conn.port}"
    spec_url = "#{base_url}/api/openapi"

    # Swagger UI HTML with JWT authorization configuration
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Expense Tracker API Documentation</title>
        <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui.css" />
        <style>
            html {
                box-sizing: border-box;
                overflow: -moz-scrollbars-vertical;
                overflow-y: scroll;
            }
            *, *:before, *:after {
                box-sizing: inherit;
            }
            body {
                margin:0;
                background: #fafafa;
            }
        </style>
    </head>
    <body>
        <div id="swagger-ui"></div>
        <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-bundle.js"></script>
        <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-standalone-preset.js"></script>
        <script>
            window.onload = function() {
                const ui = SwaggerUIBundle({
                    url: '#{spec_url}',
                    dom_id: '#swagger-ui',
                    deepLinking: true,
                    presets: [
                        SwaggerUIBundle.presets.apis,
                        SwaggerUIStandalonePreset
                    ],
                    plugins: [
                        SwaggerUIBundle.plugins.DownloadUrl
                    ],
                    layout: "StandaloneLayout",
                    // Configure JWT authorization
                    onComplete: function() {
                        // Add authorization button functionality
                        ui.preauthorizeApiKey('bearerAuth', 'Bearer ');
                    },
                    // Request interceptor to ensure proper JWT format
                    requestInterceptor: function(request) {
                        if (request.headers.Authorization && !request.headers.Authorization.startsWith('Bearer ')) {
                            request.headers.Authorization = 'Bearer ' + request.headers.Authorization;
                        }
                        return request;
                    }
                });
            };
        </script>
    </body>
    </html>
    """

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html_content)
  end
end
