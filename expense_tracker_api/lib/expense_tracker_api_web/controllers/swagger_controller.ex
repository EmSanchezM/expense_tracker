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
    if ApiDocsConfig.enabled?() do
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
    if ApiDocsConfig.enabled?() do
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

    # Swagger UI HTML with enhanced JWT authorization configuration
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
            .jwt-helper {
                background: #e8f4fd;
                border: 1px solid #b3d9ff;
                border-radius: 4px;
                padding: 15px;
                margin: 20px;
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            }
            .jwt-helper h3 {
                margin-top: 0;
                color: #1976d2;
            }
            .jwt-helper ol {
                margin: 10px 0;
                padding-left: 20px;
            }
            .jwt-helper li {
                margin: 5px 0;
            }
            .jwt-helper code {
                background: #f5f5f5;
                padding: 2px 4px;
                border-radius: 3px;
                font-family: Monaco, Consolas, monospace;
            }
            .jwt-token-display {
                background: #f8f9fa;
                border: 1px solid #dee2e6;
                border-radius: 4px;
                padding: 10px;
                margin: 10px 0;
                font-family: Monaco, Consolas, monospace;
                font-size: 12px;
                word-break: break-all;
                display: none;
            }
            .copy-button {
                background: #28a745;
                color: white;
                border: none;
                padding: 5px 10px;
                border-radius: 3px;
                cursor: pointer;
                margin-left: 10px;
            }
            .copy-button:hover {
                background: #218838;
            }
        </style>
    </head>
    <body>

        <div id="swagger-ui"></div>
        <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-bundle.js"></script>
        <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-standalone-preset.js"></script>
        <script>
            let lastJwtToken = null;

            function copyToken() {
                if (lastJwtToken) {
                    navigator.clipboard.writeText(lastJwtToken).then(function() {
                        const button = document.querySelector('.copy-button');
                        const originalText = button.textContent;
                        button.textContent = 'Copied!';
                        button.style.background = '#17a2b8';
                        setTimeout(() => {
                            button.textContent = originalText;
                            button.style.background = '#28a745';
                        }, 2000);
                    });
                }
            }

            function displayToken(token) {
                lastJwtToken = token;
                document.getElementById('token-value').textContent = token;
                document.getElementById('token-display').style.display = 'block';
            }

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
                        console.log('Swagger UI loaded successfully');
                        console.log('💡 Tip: Use the login endpoint first, then authorize with your JWT token');
                    },
                    // Request interceptor to ensure proper JWT format and capture tokens
                    requestInterceptor: function(request) {
                        // Ensure Bearer prefix for Authorization header
                        if (request.headers.Authorization && !request.headers.Authorization.startsWith('Bearer ')) {
                            request.headers.Authorization = 'Bearer ' + request.headers.Authorization;
                        }
                        return request;
                    },
                    // Response interceptor to capture JWT tokens from login responses
                    responseInterceptor: function(response) {
                        // Check if this is a login response with a token
                        if (response.url.includes('/api/auth/login') && response.status === 200) {
                            try {
                                const responseData = JSON.parse(response.text);
                                if (responseData.token) {
                                    displayToken(responseData.token);
                                    console.log('🎉 JWT Token received! Check the helper box above to copy it.');
                                }
                            } catch (e) {
                                console.log('Could not parse login response');
                            }
                        }
                        return response;
                    }
                });

                // Add some helpful console messages
                console.log('🚀 Expense Tracker API Documentation loaded');
                console.log('📖 Quick start: Try the login endpoint first to get your JWT token');
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
