# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# This script uses the SeedDataGenerator to create test users and expenses
# for development and testing purposes.

alias ExpenseTrackerApi.SeedData.SeedDataGenerator

IO.puts("🌱 Starting database seeding...")
IO.puts("=" |> String.duplicate(50))

IO.puts("🔍 Performing pre-flight checks...")

try do
  env = Application.get_env(:expense_tracker_api, :environment, :dev)
  IO.puts("   Environment: #{env}")

  if env == :prod do
    IO.puts("⚠️  WARNING: Running in production environment!")
    IO.puts("   This will create test data in your production database.")
    IO.puts("   Press Ctrl+C to cancel, or any key to continue...")
    IO.read(:line)
  end

  unless Code.ensure_loaded?(SeedDataGenerator) do
    raise "SeedDataGenerator module not found. Please ensure the application is compiled."
  end

  IO.puts("✅ Pre-flight checks completed")
  IO.puts("")

  # Run the seeding process
  case SeedDataGenerator.run() do
    :ok ->
      IO.puts("")
      IO.puts("=" |> String.duplicate(50))
      IO.puts("✅ Database seeding completed successfully!")
      IO.puts("")
      IO.puts("Test users created:")
      IO.puts("  • juan.perez@example.com (password: password123)")
      IO.puts("  • maria.garcia@example.com (password: password123)")
      IO.puts("")
      IO.puts("You can now test the API with these credentials!")
      IO.puts("=" |> String.duplicate(50))

      System.halt(0)

    error ->
      IO.puts("❌ Seeding failed with unexpected result: #{inspect(error)}")
      IO.puts("This should not happen - please check the logs for more details.")
      System.halt(1)
  end
rescue
  error ->
    IO.puts("")
    IO.puts("=" |> String.duplicate(50))
    IO.puts("❌ Database seeding failed!")
    IO.puts("")

    case error do
      %ArgumentError{message: message} ->
        IO.puts("Validation Error: #{message}")
      %RuntimeError{message: message} ->
        IO.puts("Runtime Error: #{message}")
      %Ecto.Query.CastError{} ->
        IO.puts("Database Query Error: Invalid data type or format")
      %Postgrex.Error{} = pg_error ->
        IO.puts("Database Connection Error: #{pg_error.message}")
      _ ->
        IO.puts("Unexpected Error: #{inspect(error)}")
    end

    IO.puts("")
    IO.puts("Troubleshooting tips:")
    IO.puts("  1. Ensure the database is running and accessible")
    IO.puts("  2. Run 'mix ecto.migrate' to ensure schema is up to date")
    IO.puts("  3. Check database connection configuration")
    IO.puts("  4. Verify all dependencies are compiled with 'mix compile'")
    IO.puts("")
    IO.puts("Full error details:")
    IO.puts("#{inspect(error)}")
    IO.puts("")
    IO.puts("Stack trace:")
    IO.puts(Exception.format_stacktrace(__STACKTRACE__))

    System.halt(1)
end
