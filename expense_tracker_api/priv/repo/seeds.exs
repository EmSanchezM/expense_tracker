# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# This script uses the SeedDataGenerator to create test users and expenses
# for development and testing purposes.

alias ExpenseTrackerApi.SeedData.SeedDataGenerator

IO.puts("🌱 Starting database seeding...")
IO.puts("=" |> String.duplicate(50))

try do
  case SeedDataGenerator.run() do
    :ok ->
      IO.puts("✅ Database seeding completed successfully!")
      IO.puts("")
      IO.puts("Test users created:")
      IO.puts("  • juan.perez@example.com (password: password123)")
      IO.puts("  • maria.garcia@example.com (password: password123)")
      IO.puts("You can now test the API with these credentials!")

      System.halt(0)

    error ->
      IO.puts("❌ Seeding failed with unexpected result: #{inspect(error)}")
      System.halt(1)
  end
rescue
  error ->
    IO.puts("❌ Database seeding failed!")
    IO.puts("Error: #{inspect(error)}")

    IO.puts("Stack trace:")
    IO.puts(Exception.format_stacktrace(__STACKTRACE__))

    System.halt(1)
end
