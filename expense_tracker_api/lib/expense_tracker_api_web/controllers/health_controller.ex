defmodule ExpenseTrackerApiWeb.HealthController do
  use ExpenseTrackerApiWeb, :controller

  def index(conn, _params) do
    json(conn, %{
      status: "ok",
      message: "Expense Tracker API is running",
      timestamp: DateTime.utc_now()
    })
  end
end
