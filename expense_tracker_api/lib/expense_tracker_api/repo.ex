defmodule ExpenseTrackerApi.Repo do
  use Ecto.Repo,
    otp_app: :expense_tracker_api,
    adapter: Ecto.Adapters.Postgres
end
