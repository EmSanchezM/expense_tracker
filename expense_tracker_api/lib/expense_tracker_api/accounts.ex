defmodule ExpenseTrackerApi.Accounts do
  @moduledoc """
  The Accounts context.

  Note: This implementation uses Pbkdf2 for password hashing.
  In production environments with proper build tools, consider using Bcrypt
  as specified in the requirements for enhanced security.
  """

  import Ecto.Query, warn: false
  alias ExpenseTrackerApi.Repo
  alias ExpenseTrackerApi.Accounts.User

  @doc """
  Gets a single user.

  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Authenticates a user by email and password.

  ## Examples

      iex> authenticate_user("user@example.com", "correct_password")
      {:ok, %User{}}

      iex> authenticate_user("user@example.com", "wrong_password")
      {:error, :invalid_credentials}

  """
  def authenticate_user(email, password) when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)

    if user && Pbkdf2.verify_pass(password, user.password_hash) do
      {:ok, user}
    else
      Pbkdf2.no_user_verify()
      {:error, :invalid_credentials}
    end
  end
end
