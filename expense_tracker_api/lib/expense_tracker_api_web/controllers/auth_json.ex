defmodule ExpenseTrackerApiWeb.AuthJSON do
  @moduledoc """
  Renders user data.
  """

  @doc """
  Renders a single user.
  """
  def user(%{user: user}) do
    %{
      data: %{
        id: user.id,
        email: user.email,
        name: user.name
      }
    }
  end

  @doc """
  Renders user data for authentication responses.
  """
  def auth(%{user: user, token: token}) do
    %{
      data: %{
        token: token,
        user: %{
          id: user.id,
          email: user.email,
          name: user.name
        }
      }
    }
  end
end
