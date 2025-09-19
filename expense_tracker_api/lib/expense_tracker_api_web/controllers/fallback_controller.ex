defmodule ExpenseTrackerApiWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use ExpenseTrackerApiWeb, :controller

  alias ExpenseTrackerApiWeb.ErrorJSON

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ErrorJSON)
    |> render(:validation_error, changeset: changeset)
  end

  # This clause handles resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(ErrorJSON)
    |> render(:not_found)
  end

  # This clause handles unauthorized access (authentication required)
  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(ErrorJSON)
    |> render(:unauthorized)
  end

  # This clause handles forbidden access (authorization failed)
  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(ErrorJSON)
    |> render(:forbidden)
  end

  # This clause handles bad request errors
  def call(conn, {:error, :bad_request}) do
    conn
    |> put_status(:bad_request)
    |> put_view(ErrorJSON)
    |> render(:bad_request)
  end

  # This clause handles invalid credentials specifically
  def call(conn, {:error, :invalid_credentials}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(ErrorJSON)
    |> render(:unauthorized, message: "Invalid credentials")
  end

  # This clause handles generic error messages
  def call(conn, {:error, message}) when is_binary(message) do
    conn
    |> put_status(:bad_request)
    |> put_view(ErrorJSON)
    |> render(:error, message: message)
  end

  # This clause handles any other error tuples
  def call(conn, {:error, _reason}) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(ErrorJSON)
    |> render(:internal_server_error)
  end
end
