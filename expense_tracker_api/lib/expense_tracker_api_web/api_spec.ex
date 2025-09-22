defmodule ExpenseTrackerApiWeb.ApiSpec do
  alias OpenApiSpex.{Components, Info, OpenApi, Paths, Server}
  alias ExpenseTrackerApiWeb.{Endpoint, Router}
  @behaviour OpenApiSpex.OpenApi

  @impl OpenApiSpex.OpenApi
  def spec do
    %OpenApi{
      servers: [
        # Run `mix phx.server` in a terminal window
        Server.from_endpoint(Endpoint)
      ],
      info: %Info{
        title: "Expense Tracker API",
        version: "1.0.0",
        description: """
        API for managing personal expenses with user authentication and expense tracking capabilities.

        ## Authentication

        This API uses JWT (JSON Web Tokens) for authentication. To access protected endpoints:

        1. Register a new account or login with existing credentials
        2. Use the returned JWT token in the Authorization header: `Bearer <token>`
        3. The token will be validated for all protected endpoints

        ### 🔐 JWT Authentication Quick Start

        First, use the POST /api/auth/login endpoint to get your JWT token
        Copy the token from the response (without quotes)
        Click the "Authorize" button above
        Paste your token in the "Value" field (no need to add "Bearer ")
        Click "Authorize" and then "Close"
        Now you can test all protected endpoints! 🎉

        ## Features

        - User registration and authentication
        - Personal expense management (CRUD operations)
        - Expense filtering by date ranges and time periods
        - Categorized expense tracking
        - Health check endpoint for monitoring
        """
      },
      # Populate the paths from a phoenix router
      paths: Paths.from_router(Router),
      components: %Components{
        securitySchemes: %{
          "bearerAuth" => %OpenApiSpex.SecurityScheme{
            type: "http",
            scheme: "bearer",
            bearerFormat: "JWT",
            description: "JWT token obtained from login endpoint"
          }
        }
      }
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
