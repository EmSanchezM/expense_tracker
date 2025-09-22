defmodule ExpenseTrackerApi.Repo.Migrations.AddCurrencyToExpenses do
  use Ecto.Migration

  def change do
    alter table(:expenses) do
      add(:currency, :string, size: 3, null: false, default: "USD")
    end

    create(index(:expenses, [:currency]))
  end
end
