defmodule ExpenseTrackerApi.Expenses.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  @categories [:groceries, :leisure, :electronics, :utilities, :clothing, :health, :others]

  schema "expenses" do
    field :amount, :decimal
    field :description, :string
    field :category, Ecto.Enum, values: @categories
    field :date, :date
    field :currency, :string

    belongs_to :user, ExpenseTrackerApi.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [:amount, :description, :category, :date, :currency, :user_id])
    |> put_default_date()
    |> put_default_category()
    |> put_default_currency()
    |> validate_required([:amount, :description, :category, :currency, :user_id])
    |> validate_number(:amount, greater_than: 0)
    |> validate_length(:description, min: 1, max: 255)
    |> validate_inclusion(:category, @categories)
    |> validate_currency_format()
  end

  defp put_default_date(%Ecto.Changeset{changes: %{date: _}} = changeset), do: changeset
  defp put_default_date(changeset) do
    put_change(changeset, :date, Date.utc_today())
  end

  defp put_default_category(%Ecto.Changeset{changes: %{category: _}} = changeset), do: changeset
  defp put_default_category(changeset) do
    put_change(changeset, :category, :others)
  end

  defp put_default_currency(%Ecto.Changeset{changes: %{currency: currency}} = changeset) when currency != nil, do: changeset
  defp put_default_currency(changeset) do
    put_change(changeset, :currency, "USD")
  end

  defp validate_currency_format(changeset) do
    validate_format(changeset, :currency, ~r/^[A-Z]{3}$/,
      message: "must be a valid 3-letter ISO currency code")
  end

  def categories, do: @categories
end
