defmodule ExpenseTrackerApi.Repo.Migrations.CreateExpensesTable do
  use Ecto.Migration

  def change do
    create table(:expenses) do
      add :amount, :decimal, precision: 10, scale: 2, null: false
      add :description, :string, null: false
      add :category, :string, null: false
      add :date, :date, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:expenses, [:user_id])
    create index(:expenses, [:date])
    create index(:expenses, [:category])
  end
end
