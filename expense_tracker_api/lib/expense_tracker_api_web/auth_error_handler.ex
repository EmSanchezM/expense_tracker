defmodule ExpenseTrackerApiWeb.AuthErrorHandler do
  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    message = case type do
      :invalid_token -> "Invalid or expired token"
      :no_resource_found -> "Authentication required"
      :token_expired -> "Token has expired"
      :unauthenticated -> "Authentication required"
      _ -> "Authentication required"
    end

    body = Jason.encode!(%{
      error: %{
        message: message
      }
    })

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, body)
  end
end
