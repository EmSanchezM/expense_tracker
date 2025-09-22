defmodule ExpenseTrackerApi.SeedData.UserFactory do
  @moduledoc """
  Factory module for generating test users for seeding the database.

  This module provides functions to create realistic test user data
  with Spanish names and consistent credentials for easy testing.
  """

  @doc """
  Creates a list of 2 test users with realistic Spanish names and emails.

  Returns a list of user maps that can be used with the Accounts.create_user/1 function.
  All users have the password "password123" for easy testing.

  ## Examples

      iex> ExpenseTrackerApi.SeedData.UserFactory.create_test_users()
      [
        %{name: "Juan Pérez", email: "juan.perez@example.com", password: "password123"},
        %{name: "María García", email: "maria.garcia@example.com", password: "password123"}
      ]
  """
  def create_test_users do
    [
      user_data(1),
      user_data(2)
    ]
  end

  @doc """
  Returns specific user data based on the provided index.

  ## Parameters

    * `index` - Integer index (1 or 2) to select which user data to return

  ## Examples

      iex> ExpenseTrackerApi.SeedData.UserFactory.user_data(1)
      %{name: "Juan Pérez", email: "juan.perez@example.com", password: "password123"}

      iex> ExpenseTrackerApi.SeedData.UserFactory.user_data(2)
      %{name: "María García", email: "maria.garcia@example.com", password: "password123"}
  """
  def user_data(1) do
    %{
      name: "Juan Pérez",
      email: "juan.perez@example.com",
      password: "password123"
    }
  end

  def user_data(2) do
    %{
      name: "María García",
      email: "maria.garcia@example.com",
      password: "password123"
    }
  end

  def user_data(index) when index > 2 do
    raise ArgumentError, "Only user indices 1 and 2 are supported, got: #{index}"
  end
end
