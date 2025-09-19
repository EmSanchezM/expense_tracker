defmodule ExpenseTrackerApiWeb.AuthController do
  use ExpenseTrackerApiWeb, :controller

  alias ExpenseTrackerApi.Accounts
  alias ExpenseTrackerApi.Accounts.Guardian

  action_fallback ExpenseTrackerApiWeb.FallbackController

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
