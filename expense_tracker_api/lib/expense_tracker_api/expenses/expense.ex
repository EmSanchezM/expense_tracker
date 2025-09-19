defmodule ExpenseTrackerApi.Expenses.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  @categories [:groceries, :leisure, :electronics, :utilities, :clothing, :health, :others]

  schema "expenses" do
    field :amount, :decimal
    field :description, :string
    field :category, Ecto.Enum, values: @categories
    field :date, :date

    belongs_to :user, ExpenseTrackerApi.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [:amount, :description, :category, :date, :user_id])
    |> put_default_date()
    |> put_default_category()
    |> validate_required([:amount, :description, :category, :user_id])
    |> validate_number(:amount, greater_than: 0)
    |> validate_length(:description, min: 1, max: 255)
    |> validate_inclusion(:category, @categories)
  end

  defp put_default_date(%Ecto.Changeset{changes: %{date: _}} = changeset), do: changeset
  defp put_default_date(changeset) do
    put_change(changeset, :date, Date.utc_today())
  end

  defp put_default_category(%Ecto.Changeset{changes: %{category: _}} = changeset), do: changeset
  defp put_default_category(changeset) do
    put_change(changeset, :category, :others)
  end

  def categories, do: @categories
end
