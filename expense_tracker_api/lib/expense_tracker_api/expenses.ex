defmodule ExpenseTrackerApi.Expenses do
  @moduledoc """
  The Expenses context.
  """

  import Ecto.Query, warn: false
  alias ExpenseTrackerApi.Repo
  alias ExpenseTrackerApi.Expenses.Expense

  @doc """
  Creates an expense associated with a user.

  ## Examples

      iex> create_expense(user_id, %{amount: "100.50", description: "Groceries"})
      {:ok, %Expense{}}

      iex> create_expense(user_id, %{amount: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def create_expense(user_id, attrs \\ %{}) do
    attrs_with_user = Map.put(attrs, "user_id", user_id)

    %Expense{}
    |> Expense.changeset(attrs_with_user)
    |> Repo.insert()
  end

  @doc """
  Gets a single expense that belongs to the specified user.

  Raises `Ecto.NoResultsError` if the Expense does not exist or doesn't belong to the user.

  ## Examples

      iex> get_user_expense!(user_id, expense_id)
      %Expense{}

      iex> get_user_expense!(user_id, nonexistent_id)
      ** (Ecto.NoResultsError)

  """
  def get_user_expense!(user_id, expense_id) do
    Expense
    |> where([e], e.user_id == ^user_id and e.id == ^expense_id)
    |> Repo.one!()
  end

  @doc """
  Updates an expense.

  ## Examples

      iex> update_expense(expense, %{amount: "200.00"})
      {:ok, %Expense{}}

      iex> update_expense(expense, %{amount: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def update_expense(%Expense{} = expense, attrs) do
    expense
    |> Expense.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an expense.

  ## Examples

      iex> delete_expense(expense)
      {:ok, %Expense{}}

      iex> delete_expense(expense)
      {:error, %Ecto.Changeset{}}

  """
  def delete_expense(%Expense{} = expense) do
    Repo.delete(expense)
  end

  @doc """
  Lists expenses for a user with optional filters.

  ## Examples

      iex> list_user_expenses(user_id)
      [%Expense{}, ...]

      iex> list_user_expenses(user_id, %{period: "last_week"})
      [%Expense{}, ...]

      iex> list_user_expenses(user_id, %{from_date: ~D[2023-01-01], to_date: ~D[2023-01-31]})
      [%Expense{}, ...]

  """
  def list_user_expenses(user_id, filters \\ %{}) do
    Expense
    |> where([e], e.user_id == ^user_id)
    |> apply_date_filters(filters)
    |> order_by([e], desc: e.date)
    |> Repo.all()
  end

  defp apply_date_filters(query, %{period: period}) when period in ["last_week", "last_month", "last_3_months"] do
    days_back = case period do
      "last_week" -> 7
      "last_month" -> 30
      "last_3_months" -> 90
    end

    from_date = Date.add(Date.utc_today(), -days_back)

    query
    |> where([e], e.date >= ^from_date)
  end

  defp apply_date_filters(query, %{from_date: from_date, to_date: to_date})
       when not is_nil(from_date) and not is_nil(to_date) do
    query
    |> where([e], e.date >= ^from_date and e.date <= ^to_date)
  end

  defp apply_date_filters(query, %{from_date: from_date}) when not is_nil(from_date) do
    query
    |> where([e], e.date >= ^from_date)
  end

  defp apply_date_filters(query, %{to_date: to_date}) when not is_nil(to_date) do
    query
    |> where([e], e.date <= ^to_date)
  end

  defp apply_date_filters(query, _filters), do: query
end
