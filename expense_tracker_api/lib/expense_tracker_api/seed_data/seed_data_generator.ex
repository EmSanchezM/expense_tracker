defmodule ExpenseTrackerApi.SeedData.SeedDataGenerator do
  @moduledoc """
  Main orchestrator module for seeding the database with test data.

  This module coordinates the complete seeding process, including cleanup of existing
  seed data, creation of test users, and generation of expenses. The process is
  idempotent and can be run multiple times safely.
  """

  require Logger

  alias ExpenseTrackerApi.Repo
  alias ExpenseTrackerApi.Accounts
  alias ExpenseTrackerApi.SeedData.{UserFactory, ExpenseFactory}

  import Ecto.Query

  @doc """
  Runs the complete seeding process.

  This function orchestrates the entire seeding workflow:
  1. Cleans up existing seed data
  2. Creates test users
  3. Generates expenses for each user
  4. Provides summary feedback

  Returns `:ok` on success.

  ## Examples

      iex> ExpenseTrackerApi.SeedData.SeedDataGenerator.run()
      :ok
  """
  def run do
    Logger.info("🌱 Starting database seeding process...")

    try do
      # Step 0: Verify database connectivity
      Logger.info("🔍 Verifying database connectivity...")
      verify_database_connection()

      # Step 1: Cleanup existing seed data
      Logger.info("🧹 Cleaning up existing seed data...")
      cleanup_seed_data()

      # Step 2: Create test users
      Logger.info("👥 Creating test users...")
      users = create_seed_users()
      Logger.info("✅ Created #{length(users)} test users")

      # Step 3: Create expenses for each user
      Logger.info("💰 Generating expenses for users...")
      total_expenses = create_seed_expenses(users)
      Logger.info("✅ Created #{total_expenses} total expenses")

      # Step 4: Provide summary
      Logger.info("🎉 Seeding completed successfully!")
      Logger.info("📊 Summary:")
      Logger.info("   - Users created: #{length(users)}")
      Logger.info("   - Total expenses: #{total_expenses}")
      Logger.info("   - Test credentials: password123")

      :ok
    rescue
      error ->
        Logger.error("❌ Seeding failed: #{inspect(error)}")
        reraise error, __STACKTRACE__
    end
  end

  @doc """
  Removes existing seed data from the database.

  This function identifies and removes seed users by their email patterns
  (@example.com domain) and cascades the deletion to their associated expenses.
  The process is safe and will not affect non-seed data.

  The cleanup process:
  1. Identifies seed users by email pattern (@example.com domain)
  2. Counts associated expenses for logging purposes
  3. Deletes users (expenses are cascade deleted automatically)
  4. Handles errors gracefully and continues the seeding process

  Returns `:ok` on success, even if some cleanup operations fail.
  """
  def cleanup_seed_data do
    Logger.debug("Starting cleanup of existing seed data...")

    try do
      # Identify seed users by email pattern - using @example.com domain
      seed_user_emails = get_seed_user_emails()

      # Find existing seed users with their expense counts
      seed_users = find_seed_users(seed_user_emails)

      if length(seed_users) > 0 do
        Logger.info("🗑️  Found #{length(seed_users)} existing seed users to remove")

        # Count and log expenses that will be cascade deleted
        total_expenses = count_seed_expenses(seed_users)

        if total_expenses > 0 do
          Logger.info("🗑️  Will cascade delete #{total_expenses} associated expenses")
        end

        # Perform cleanup with error handling
        cleanup_results = delete_seed_users(seed_users)

        # Log cleanup summary
        log_cleanup_summary(cleanup_results, total_expenses)
      else
        Logger.info("ℹ️  No existing seed data found to clean up")
      end

      :ok
    rescue
      error ->
        Logger.error("❌ Cleanup failed with error: #{inspect(error)}")
        Logger.warning("⚠️  Continuing with seeding process despite cleanup failure...")
        :ok
    end
  end

  # Private helper functions

  defp verify_database_connection do
    try do
      # Simple query to test database connectivity
      Repo.query!("SELECT 1")
      Logger.debug("   ✅ Database connection verified")
      :ok
    rescue
      error ->
        Logger.error("   ❌ Database connection failed: #{inspect(error)}")
        raise "Database connection failed. Please ensure the database is running and accessible."
    end
  end

  # Private helper functions for cleanup logic

  defp get_seed_user_emails do
    # Define the specific seed user emails to ensure idempotency
    ["juan.perez@example.com", "maria.garcia@example.com"]
  end

  defp find_seed_users(seed_user_emails) do
    from(u in ExpenseTrackerApi.Accounts.User,
      where: u.email in ^seed_user_emails,
      preload: [:expenses]
    )
    |> Repo.all()
  end

  defp count_seed_expenses(seed_users) do
    Enum.reduce(seed_users, 0, fn user, acc ->
      acc + length(user.expenses)
    end)
  end

  defp delete_seed_users(seed_users) do
    Enum.map(seed_users, fn user ->
      case Repo.delete(user) do
        {:ok, deleted_user} ->
          Logger.debug("   ✅ Removed user: #{deleted_user.email}")
          {:ok, deleted_user}
        {:error, changeset} ->
          Logger.error("   ❌ Failed to remove user #{user.email}: #{format_changeset_errors(changeset)}")
          {:error, user, changeset}
      end
    end)
  end

  defp log_cleanup_summary(cleanup_results, total_expenses) do
    successful_deletions = Enum.count(cleanup_results, fn result ->
      match?({:ok, _}, result)
    end)

    failed_deletions = Enum.count(cleanup_results, fn result ->
      match?({:error, _, _}, result)
    end)

    if failed_deletions > 0 do
      Logger.warning("⚠️  Cleanup completed with #{failed_deletions} failures out of #{length(cleanup_results)} users")
      Logger.warning("   Successfully removed: #{successful_deletions} users")
    else
      Logger.info("✅ Cleanup completed successfully")
      Logger.info("   Removed: #{successful_deletions} users and #{total_expenses} expenses")
    end
  end

  defp format_changeset_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {message, _}} -> "#{field}: #{message}" end)
    |> Enum.join(", ")
  end

  @doc """
  Creates the test users using the UserFactory.

  This function ensures idempotency by handling cases where users might already exist.
  If a user creation fails due to email uniqueness constraint, it will attempt to
  find and return the existing user instead.

  Returns a list of user structs (either newly created or existing).
  """
  def create_seed_users do
    user_data_list = UserFactory.create_test_users()

    Enum.map(user_data_list, fn user_data ->
      case Accounts.create_user(user_data) do
        {:ok, user} ->
          Logger.debug("   ✅ Created user: #{user.email}")
          user
        {:error, changeset} ->
          # Check if the error is due to email uniqueness constraint
          if email_uniqueness_error?(changeset) do
            Logger.debug("   ℹ️  User #{user_data.email} already exists, fetching existing user...")
            case find_existing_user(user_data.email) do
              {:ok, existing_user} ->
                Logger.debug("   ✅ Found existing user: #{existing_user.email}")
                existing_user
              {:error, :not_found} ->
                Logger.error("   ❌ User creation failed and existing user not found: #{user_data.email}")
                raise "Failed to create or find user: #{user_data.email}"
            end
          else
            Logger.error("   ❌ Failed to create user #{user_data.email}: #{format_changeset_errors(changeset)}")
            raise "Failed to create user #{user_data.email}: #{format_changeset_errors(changeset)}"
          end
      end
    end)
  end

  # Private helper functions for user creation

  defp email_uniqueness_error?(changeset) do
    Enum.any?(changeset.errors, fn {field, {message, _}} ->
      field == :email and String.contains?(message, "has already been taken")
    end)
  end

  defp find_existing_user(email) do
    case Repo.get_by(ExpenseTrackerApi.Accounts.User, email: email) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  @doc """
  Creates expenses for all provided users using the ExpenseFactory.

  This function handles expense creation errors gracefully, continuing with
  the process even if some expenses fail to create. It provides detailed
  logging for both successes and failures.

  Returns the total number of expenses successfully created.
  """
  def create_seed_expenses(users) do
    Enum.reduce(users, 0, fn user, total_count ->
      Logger.info("   💰 Generating expenses for #{user.name}...")

      expense_data_list = ExpenseFactory.create_expenses_for_user(user.id)

      {created_count, failed_count} = create_expenses_for_single_user(user, expense_data_list)

      if failed_count > 0 do
        Logger.warning("   ⚠️  Created #{created_count}/#{length(expense_data_list)} expenses for #{user.name} (#{failed_count} failed)")
      else
        Logger.info("   ✅ Created #{created_count}/#{length(expense_data_list)} expenses for #{user.name}")
      end

      total_count + created_count
    end)
  end

  # Private helper function for expense creation

  defp create_expenses_for_single_user(_user, expense_data_list) do
    Enum.reduce(expense_data_list, {0, 0}, fn expense_data, {created_count, failed_count} ->
      # Since ExpenseFactory already includes user_id, we need to create the expense directly
      # without using the Expenses.create_expense/2 function which adds user_id again
      case create_expense_directly(expense_data) do
        {:ok, expense} ->
          Logger.debug("     ✅ Created expense: #{expense.description} (#{expense.amount})")
          {created_count + 1, failed_count}
        {:error, changeset} ->
          Logger.warning("     ❌ Failed to create expense: #{format_changeset_errors(changeset)}")
          Logger.debug("       Expense data: #{inspect(expense_data)}")
          {created_count, failed_count + 1}
      end
    end)
  end

  defp create_expense_directly(expense_data) do
    %ExpenseTrackerApi.Expenses.Expense{}
    |> ExpenseTrackerApi.Expenses.Expense.changeset(expense_data)
    |> Repo.insert()
  end
end
