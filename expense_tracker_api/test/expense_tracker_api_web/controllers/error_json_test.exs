defmodule ExpenseTrackerApiWeb.ErrorJSONTest do
  use ExpenseTrackerApiWeb.ConnCase, async: true

  test "renders 404" do
    assert ExpenseTrackerApiWeb.ErrorJSON.render("404.json", %{}) == %{error: %{message: "Resource not found"}}
  end

  test "renders 500" do
    assert ExpenseTrackerApiWeb.ErrorJSON.render("500.json", %{}) ==
             %{error: %{message: "Internal server error"}}
  end
end
