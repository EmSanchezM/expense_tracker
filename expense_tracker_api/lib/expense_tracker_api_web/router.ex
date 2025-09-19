defmodule ExpenseTrackerApiWeb.Router do
  use ExpenseTrackerApiWeb, :router

  # Get CORS origins from environment variable at compile time
  @cors_origins (case System.get_env("CORS_ORIGINS") do
                   nil ->
                     ["http://localhost:3000", "http://localhost:5173", "http://localhost:8080"]

                   origins ->
                     String.split(origins, ",")
                 end)

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    # Configure CORS for frontend integration
    # - Allows common frontend development ports
    # - Enables credentials for JWT authentication
    # - Includes Authorization header for JWT tokens
    plug(CORSPlug,
      origin: @cors_origins,
      credentials: true,
      headers: [
        "Authorization",
        "Content-Type",
        "Accept",
        "Origin",
        "User-Agent",
        "DNT",
        "Cache-Control",
        "X-Mx-ReqToken",
        "Keep-Alive",
        "X-Requested-With",
        "If-Modified-Since",
        "X-CSRF-Token"
      ],
      methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    )

    plug(:accepts, ["json"])
  end

  pipeline :api_auth do
    plug(Guardian.Plug.Pipeline,
      module: ExpenseTrackerApi.Accounts.Guardian,
      error_handler: ExpenseTrackerApiWeb.AuthErrorHandler
    )

    plug(Guardian.Plug.VerifyHeader, scheme: "Bearer")
    plug(Guardian.Plug.EnsureAuthenticated)
    plug(Guardian.Plug.LoadResource)
  end

  scope "/", ExpenseTrackerApiWeb do
    pipe_through(:api)

    get("/", HealthController, :index)
  end

  scope "/api", ExpenseTrackerApiWeb do
    pipe_through(:api)

    # Authentication routes
    post("/auth/register", AuthController, :register)
    post("/auth/login", AuthController, :login)
  end

  # API Documentation routes (environment-controlled)
  # Only register these routes if documentation is enabled
  if ExpenseTrackerApiWeb.ApiDocsConfig.enabled?() do
    scope "/api", ExpenseTrackerApiWeb do
      pipe_through(:browser)
      get("/docs", SwaggerController, :index)
    end

    scope "/api", ExpenseTrackerApiWeb do
      pipe_through(:api)
      # OpenAPI specification endpoint
      get("/openapi", SwaggerController, :spec)
    end
  end

  scope "/api", ExpenseTrackerApiWeb do
    pipe_through([:api, :api_auth])

    # Expense routes (authenticated)
    resources("/expenses", ExpenseController, except: [:new, :edit])
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:expense_tracker_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through([:fetch_session, :protect_from_forgery])

      live_dashboard("/dashboard", metrics: ExpenseTrackerApiWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
