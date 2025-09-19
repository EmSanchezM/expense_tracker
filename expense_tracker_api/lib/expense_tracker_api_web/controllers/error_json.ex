defmodule ExpenseTrackerApiWeb.ErrorJSON do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on JSON requests.

  See config/config.exs.
  """

  @doc """
  Renders validation errors from Ecto changesets.
  """
  def validation_error(%{changeset: changeset}) do
    %{
      error: %{
        message: "Validation failed",
        details: format_changeset_errors(changeset)
      }
    }
  end

  @doc """
  Renders authentication errors.
  """
  def unauthorized(%{message: message}) do
    %{
      error: %{
        message: message
      }
    }
  end

  def unauthorized(_assigns) do
    %{
      error: %{
        message: "Authentication required"
      }
    }
  end

  @doc """
  Renders authorization errors.
  """
  def forbidden(%{message: message}) do
    %{
      error: %{
        message: message
      }
    }
  end

  def forbidden(_assigns) do
    %{
      error: %{
        message: "Access denied"
      }
    }
  end

  @doc """
  Renders not found errors.
  """
  def not_found(%{message: message}) do
    %{
      error: %{
        message: message
      }
    }
  end

  def not_found(_assigns) do
    %{
      error: %{
        message: "Resource not found"
      }
    }
  end

  @doc """
  Renders bad request errors.
  """
  def bad_request(%{message: message}) do
    %{
      error: %{
        message: message
      }
    }
  end

  def bad_request(_assigns) do
    %{
      error: %{
        message: "Bad request"
      }
    }
  end

  @doc """
  Renders internal server errors without exposing internal details.
  """
  def internal_server_error(_assigns) do
    %{
      error: %{
        message: "Internal server error"
      }
    }
  end

  @doc """
  Renders generic error messages.
  """
  def error(%{message: message}) do
    %{
      error: %{
        message: message
      }
    }
  end

  # Handle 400 Bad Request
  def render("400.json", _assigns) do
    %{
      error: %{
        message: "Bad request"
      }
    }
  end

  # Handle 401 Unauthorized
  def render("401.json", _assigns) do
    %{
      error: %{
        message: "Authentication required"
      }
    }
  end

  # Handle 403 Forbidden
  def render("403.json", _assigns) do
    %{
      error: %{
        message: "Access denied"
      }
    }
  end

  # Handle 404 Not Found
  def render("404.json", _assigns) do
    %{
      error: %{
        message: "Resource not found"
      }
    }
  end

  # Handle 422 Unprocessable Entity
  def render("422.json", _assigns) do
    %{
      error: %{
        message: "Validation failed"
      }
    }
  end

  # Handle 500 Internal Server Error - don't expose internal details
  def render("500.json", _assigns) do
    %{
      error: %{
        message: "Internal server error"
      }
    }
  end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def render(template, _assigns) do
    %{
      error: %{
        message: Phoenix.Controller.status_message_from_template(template)
      }
    }
  end

  # Private helper function to format changeset errors
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
