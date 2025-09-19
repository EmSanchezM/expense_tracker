defmodule ExpenseTrackerApiWeb.AuthController do
  use ExpenseTrackerApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias ExpenseTrackerApi.Accounts
  alias ExpenseTrackerApi.Accounts.Guardian
  alias ExpenseTrackerApiWeb.Schemas.AuthSchema
  alias ExpenseTrackerApiWeb.Schemas.ErrorSchema

  action_fallback ExpenseTrackerApiWeb.FallbackController

  tags(["Authentication"])

  operation(:register,
    summary: "Register a new user",
    description: "Create a new user account with email, password, and name",
    request_body:
      {"User registration data", "application/json", AuthSchema.RegisterRequest, required: true},
    responses: [
      created: {"User registered successfully", "application/json", AuthSchema.RegisterResponse},
      unprocessable_entity:
        {"Validation errors", "application/json", ErrorSchema.ValidationError},
      internal_server_error:
        {"Internal server error", "application/json", ErrorSchema.InternalServerError}
    ]
  )

  @doc """
  Register a new user
  """
  def register(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> render(:user, user: user)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ExpenseTrackerApiWeb.ErrorJSON)
        |> render(:validation_error, changeset: changeset)
    end
  end

  operation(:login,
    summary: "User login",
    description: "Authenticate user with email and password, returns JWT token on success",
    request_body:
      {"User login credentials", "application/json", AuthSchema.LoginRequest, required: true},
    responses: [
      ok: {"Login successful", "application/json", AuthSchema.LoginResponse},
      unauthorized: {"Invalid credentials", "application/json", ErrorSchema.UnauthorizedError},
      bad_request: {"Missing required parameters", "application/json", ErrorSchema.ValidationError},
      internal_server_error:
        {"Internal server error", "application/json", ErrorSchema.InternalServerError}
    ]
  )

  @doc """
  Login user and return JWT token
  """
  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)

        conn
        |> put_status(:ok)
        |> render(:auth, user: user, token: token)

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> put_view(ExpenseTrackerApiWeb.ErrorJSON)
        |> render(:unauthorized, message: "Invalid credentials")
    end
  end

  # Handle missing parameters
  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> put_view(ExpenseTrackerApiWeb.ErrorJSON)
    |> render(:bad_request, message: "Email and password are required")
  end


end
