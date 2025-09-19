defmodule ExpenseTrackerApiWeb.HealthController do
  use ExpenseTrackerApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias ExpenseTrackerApiWeb.Schemas.HealthSchema

  tags(["Health"])

  operation(:index,
    summary: "Health check",
    description: "Check the API health status and get basic system information",
    responses: [
      ok: {"API is healthy and running", "application/json", HealthSchema.HealthResponse}
    ]
  )

  @doc """
  Health check endpoint
  """
  def index(conn, _params) do
    json(conn, %{
      status: "ok",
      message: "Expense Tracker API is running",
      timestamp: DateTime.utc_now()
    })
  end
end
