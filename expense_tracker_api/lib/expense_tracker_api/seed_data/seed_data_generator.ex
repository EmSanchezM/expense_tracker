defmodule ExpenseTrackerApi.SeedData.SeedDataGenerator do
  @moduledoc """
  Main orchestrator module for seeding the database with test data.

  This module coordinates the complete seeding process, including cleanup of existing
  seed data, creation of test users, and generation of expenses. The process is
  idempotent and can be run multiple times safely.

  ## Seeding Strategy

  The seeding system creates realistic test data that enables comprehensive testing
  of all application features:

  ### User Generation
  - Creates exactly 2 test users with Spanish names
  - Uses consistent credentials (password: "password123") for easy testing
  - Emails follow the pattern: `name.surname@example.com`
  - All users are validated against the User schema before insertion

  ### Expense Generation
  - Each user receives exactly 10 expenses (20 total)
  - Expenses are distributed across 6 categories with realistic proportions
  - Temporal distribution spans the last 6 months to enable date filtering tests
  - All amounts and descriptions are category-appropriate and realistic

  ## Data Distribution

  ### Category Distribution (per user)
  - **Groceries**: 3 expenses (30%) - $20-$150 range
  - **Utilities**: 2 expenses (20%) - $50-$300 range
  - **Leisure**: 2 expenses (20%) - $15-$200 range
  - **Health**: 1 expense (10%) - $30-$400 range
  - **Electronics**: 1 expense (10%) - $100-$800 range
  - **Clothing**: 1 expense (10%) - $25-$250 range

  ### Temporal Distribution (per user)
  - **Last week**: ~2 expenses
  - **Last month**: ~4 expenses total
  - **Last 3 months**: ~7 expenses total
  - **Last 6 months**: 10 expenses total

  This distribution ensures that all date-based filtering functionality can be
  thoroughly tested with realistic data patterns.

  ## Idempotency and Safety

  The seeding process is designed to be safe and repeatable:

  - **Cleanup**: Removes existing seed data before creating new data
  - **Identification**: Seed users are identified by their @example.com email domain
  - **Cascade Deletion**: User deletion automatically removes associated expenses
  - **Error Handling**: Graceful handling of failures with detailed logging
  - **Validation**: All data is validated against schemas before insertion

  ## Usage

  The seeding process can be triggered in several ways:

      # Via seeds.exs file
      mix run priv/repo/seeds.exs

      # Directly in IEx
      ExpenseTrackerApi.SeedData.SeedDataGenerator.run()

      # Cleanup only
      ExpenseTrackerApi.SeedData.SeedDataGenerator.cleanup_seed_data()

  ## Error Handling

  The module provides comprehensive error handling:

  - **Database connectivity**: Verifies connection before starting
  - **Schema validation**: Ensures all data meets requirements
  - **Transient errors**: Implements retry logic for temporary failures
  - **Partial failures**: Continues processing even if some operations fail
  - **Detailed logging**: Provides clear feedback on all operations

  ## Testing Integration

  The generated data is specifically designed to support testing scenarios:

  - **Authentication**: Test login with known credentials
  - **Date filtering**: Test all temporal filter ranges
  - **Category filtering**: Test filtering by all expense categories
  - **Pagination**: Sufficient data to test pagination logic
  - **Edge cases**: Includes various amount ranges and date distributions
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
      # Step 0: Verify database connectivity and validate environment
      Logger.info("🔍 Verifying database connectivity and environment...")
      validate_environment()

      # Step 1: Cleanup existing seed data
      Logger.info("🧹 Cleaning up existing seed data...")
      cleanup_seed_data()

      # Step 2: Create test users with comprehensive error handling
      Logger.info("👥 Creating test users...")
      users = create_seed_users()
      validate_created_users!(users)
      Logger.info("✅ Created #{length(users)} test users")

      # Step 3: Create expenses for each user with error handling
      Logger.info("💰 Generating expenses for users...")
      total_expenses = create_seed_expenses(users)
      validate_expense_creation!(total_expenses, users)
      Logger.info("✅ Created #{total_expenses} total expenses")

      # Step 4: Final validation and summary
      Logger.info("🔍 Performing final validation...")
      perform_final_validation(users, total_expenses)

      Logger.info("🎉 Seeding completed successfully!")
      Logger.info("📊 Summary:")
      Logger.info("   - Users created: #{length(users)}")
      Logger.info("   - Total expenses: #{total_expenses}")
      Logger.info("   - Test credentials: password123")

      :ok
    rescue
      error ->
        Logger.error("❌ Seeding failed: #{inspect(error)}")
        Logger.error("Stack trace: #{Exception.format_stacktrace(__STACKTRACE__)}")
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

  defp validate_environment do
    # Verify database connectivity
    verify_database_connection()

    # Verify required modules are available
    verify_required_modules()

    # Verify database schema is up to date
    verify_database_schema()

    Logger.debug("   ✅ Environment validation completed")
  end

  defp verify_database_connection do
    try do
      # Test basic connectivity
      Repo.query!("SELECT 1")

      # Test that we can access the users table
      Repo.query!("SELECT COUNT(*) FROM users")

      # Test that we can access the expenses table
      Repo.query!("SELECT COUNT(*) FROM expenses")

      Logger.debug("   ✅ Database connection and table access verified")
      :ok
    rescue
      error ->
        Logger.error("   ❌ Database connection failed: #{inspect(error)}")

        raise "Database connection failed. Please ensure the database is running and accessible. Error: #{inspect(error)}"
    end
  end

  defp verify_required_modules do
    required_modules = [
      ExpenseTrackerApi.Accounts,
      ExpenseTrackerApi.Accounts.User,
      ExpenseTrackerApi.Expenses.Expense,
      ExpenseTrackerApi.SeedData.UserFactory,
      ExpenseTrackerApi.SeedData.ExpenseFactory
    ]

    Enum.each(required_modules, fn module ->
      unless Code.ensure_loaded?(module) do
        raise "Required module #{module} is not available. Please ensure all dependencies are compiled."
      end
    end)

    Logger.debug("   ✅ Required modules verified")
  end

  defp verify_database_schema do
    try do
      # Verify users table has required columns
      user_columns = get_table_columns("users")

      required_user_columns = [
        "id",
        "email",
        "password_hash",
        "name",
        "inserted_at",
        "updated_at"
      ]

      missing_user_columns = required_user_columns -- user_columns

      if length(missing_user_columns) > 0 do
        raise "Users table is missing required columns: #{Enum.join(missing_user_columns, ", ")}"
      end

      # Verify expenses table has required columns
      expense_columns = get_table_columns("expenses")

      required_expense_columns = [
        "id",
        "amount",
        "description",
        "category",
        "date",
        "user_id",
        "inserted_at",
        "updated_at"
      ]

      missing_expense_columns = required_expense_columns -- expense_columns

      if length(missing_expense_columns) > 0 do
        raise "Expenses table is missing required columns: #{Enum.join(missing_expense_columns, ", ")}"
      end

      Logger.debug("   ✅ Database schema verified")
    rescue
      error ->
        Logger.error("   ❌ Database schema verification failed: #{inspect(error)}")

        raise "Database schema verification failed. Please run migrations. Error: #{inspect(error)}"
    end
  end

  defp get_table_columns(table_name) do
    query = """
    SELECT column_name
    FROM information_schema.columns
    WHERE table_name = $1
    ORDER BY ordinal_position
    """

    case Repo.query(query, [table_name]) do
      {:ok, %{rows: rows}} ->
        Enum.map(rows, fn [column_name] -> column_name end)

      {:error, error} ->
        raise "Failed to query table columns for #{table_name}: #{inspect(error)}"
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
          Logger.error(
            "   ❌ Failed to remove user #{user.email}: #{format_changeset_errors(changeset)}"
          )

          {:error, user, changeset}
      end
    end)
  end

  defp log_cleanup_summary(cleanup_results, total_expenses) do
    successful_deletions =
      Enum.count(cleanup_results, fn result ->
        match?({:ok, _}, result)
      end)

    failed_deletions =
      Enum.count(cleanup_results, fn result ->
        match?({:error, _, _}, result)
      end)

    if failed_deletions > 0 do
      Logger.warning(
        "⚠️  Cleanup completed with #{failed_deletions} failures out of #{length(cleanup_results)} users"
      )

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
    try do
      user_data_list = UserFactory.create_test_users()
      Logger.debug("   📋 Generated #{length(user_data_list)} user data entries")

      users =
        Enum.map(user_data_list, fn user_data ->
          create_single_user_with_retry(user_data)
        end)

      Logger.debug("   ✅ User creation process completed")
      users
    rescue
      error ->
        Logger.error("   ❌ User creation process failed: #{inspect(error)}")
        reraise error, __STACKTRACE__
    end
  end

  defp create_single_user_with_retry(user_data, retry_count \\ 0) do
    max_retries = 3

    case Accounts.create_user(user_data) do
      {:ok, user} ->
        Logger.debug("   ✅ Created user: #{user.email}")
        validate_created_user!(user)
        user

      {:error, changeset} ->
        # Check if the error is due to email uniqueness constraint
        if email_uniqueness_error?(changeset) do
          Logger.debug("   ℹ️  User #{user_data.email} already exists, fetching existing user...")

          case find_existing_user(user_data.email) do
            {:ok, existing_user} ->
              Logger.debug("   ✅ Found existing user: #{existing_user.email}")
              validate_created_user!(existing_user)
              existing_user

            {:error, :not_found} ->
              Logger.error(
                "   ❌ User creation failed and existing user not found: #{user_data.email}"
              )

              raise "Failed to create or find user: #{user_data.email}"
          end
        else
          error_message = format_changeset_errors(changeset)
          Logger.error("   ❌ Failed to create user #{user_data.email}: #{error_message}")

          # Retry logic for transient errors
          if retry_count < max_retries and retryable_error?(changeset) do
            Logger.warning(
              "   🔄 Retrying user creation (attempt #{retry_count + 1}/#{max_retries})..."
            )

            # Exponential backoff
            :timer.sleep(1000 * (retry_count + 1))
            create_single_user_with_retry(user_data, retry_count + 1)
          else
            raise "Failed to create user #{user_data.email} after #{retry_count} retries: #{error_message}"
          end
        end
    end
  end

  defp validate_created_user!(user) do
    unless user.id && user.email && user.name && user.password_hash do
      raise "Created user is missing required fields: #{inspect(user)}"
    end

    unless String.contains?(user.email, "@") do
      raise "Created user has invalid email format: #{user.email}"
    end

    unless String.length(user.name) > 0 do
      raise "Created user has empty name"
    end

    :ok
  end

  defp retryable_error?(changeset) do
    # Check if the error might be transient (database connection issues, etc.)
    Enum.any?(changeset.errors, fn {_field, {message, _}} ->
      String.contains?(String.downcase(message), ["timeout", "connection", "unavailable"])
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
    if length(users) == 0 do
      Logger.warning("   ⚠️  No users provided for expense creation")
      0
    else
      total_count =
        Enum.reduce(users, 0, fn user, total_count ->
          Logger.info("   💰 Generating expenses for #{user.name}...")

          try do
            expense_data_list = ExpenseFactory.create_expenses_for_user(user.id)

            Logger.debug(
              "   📋 Generated #{length(expense_data_list)} expense data entries for #{user.name}"
            )

            {created_count, failed_count} =
              create_expenses_for_single_user(user, expense_data_list)

            if failed_count > 0 do
              Logger.warning(
                "   ⚠️  Created #{created_count}/#{length(expense_data_list)} expenses for #{user.name} (#{failed_count} failed)"
              )

              # If more than 50% of expenses failed, this might indicate a systemic issue
              if failed_count > length(expense_data_list) / 2 do
                Logger.error(
                  "   ❌ High failure rate (#{failed_count}/#{length(expense_data_list)}) for #{user.name} - this may indicate a systemic issue"
                )
              end
            else
              Logger.info(
                "   ✅ Created #{created_count}/#{length(expense_data_list)} expenses for #{user.name}"
              )
            end

            total_count + created_count
          rescue
            error ->
              Logger.error("   ❌ Failed to generate expenses for #{user.name}: #{inspect(error)}")
              Logger.warning("   ⚠️  Continuing with next user...")
              total_count
          end
        end)

      total_count
    end
  end

  # Private helper function for expense creation

  defp create_expenses_for_single_user(user, expense_data_list) do
    Enum.reduce(expense_data_list, {0, 0}, fn expense_data, {created_count, failed_count} ->
      case create_expense_with_retry(expense_data) do
        {:ok, expense} ->
          Logger.debug("     ✅ Created expense: #{expense.description} ($#{expense.amount})")
          validate_created_expense!(expense, user)
          {created_count + 1, failed_count}

        {:error, reason} ->
          Logger.warning("     ❌ Failed to create expense: #{reason}")
          Logger.debug("       Expense data: #{inspect(expense_data)}")
          {created_count, failed_count + 1}
      end
    end)
  end

  defp create_expense_with_retry(expense_data, retry_count \\ 0) do
    max_retries = 2

    case create_expense_directly(expense_data) do
      {:ok, expense} ->
        {:ok, expense}

      {:error, changeset} ->
        error_message = format_changeset_errors(changeset)

        # Retry logic for transient errors
        if retry_count < max_retries and retryable_expense_error?(changeset) do
          Logger.debug(
            "       🔄 Retrying expense creation (attempt #{retry_count + 1}/#{max_retries})..."
          )

          # Short exponential backoff
          :timer.sleep(500 * (retry_count + 1))
          create_expense_with_retry(expense_data, retry_count + 1)
        else
          {:error, error_message}
        end
    end
  end

  defp create_expense_directly(expense_data) do
    %ExpenseTrackerApi.Expenses.Expense{}
    |> ExpenseTrackerApi.Expenses.Expense.changeset(expense_data)
    |> Repo.insert()
  end

  defp validate_created_expense!(expense, user) do
    unless expense.id && expense.amount && expense.description && expense.category &&
             expense.user_id do
      raise "Created expense is missing required fields: #{inspect(expense)}"
    end

    unless expense.user_id == user.id do
      raise "Created expense has incorrect user_id. Expected: #{user.id}, Got: #{expense.user_id}"
    end

    unless Decimal.gt?(expense.amount, 0) do
      raise "Created expense has invalid amount: #{expense.amount}"
    end

    unless String.length(expense.description) > 0 do
      raise "Created expense has empty description"
    end

    :ok
  end

  defp retryable_expense_error?(changeset) do
    # Check if the error might be transient
    Enum.any?(changeset.errors, fn {_field, {message, _}} ->
      String.contains?(String.downcase(message), [
        "timeout",
        "connection",
        "unavailable",
        "constraint"
      ])
    end)
  end

  # New validation functions

  defp validate_created_users!(users) do
    if length(users) == 0 do
      raise "No users were created successfully"
    end

    expected_count = 2

    if length(users) != expected_count do
      Logger.warning("   ⚠️  Expected #{expected_count} users, but created #{length(users)}")
    end

    # Verify all users have unique emails
    emails = Enum.map(users, & &1.email)
    unique_emails = Enum.uniq(emails)

    if length(emails) != length(unique_emails) do
      raise "Duplicate emails found in created users: #{inspect(emails)}"
    end

    Logger.debug("   ✅ User validation completed")
    :ok
  end

  defp validate_expense_creation!(total_expenses, users) do
    expected_expenses_per_user = 10
    expected_total = length(users) * expected_expenses_per_user

    if total_expenses == 0 do
      raise "No expenses were created successfully"
    end

    # Allow for some failures
    if total_expenses < expected_total * 0.8 do
      Logger.warning(
        "   ⚠️  Expected approximately #{expected_total} expenses, but created #{total_expenses}"
      )

      Logger.warning("   ⚠️  This may indicate issues with expense generation")
    end

    Logger.debug("   ✅ Expense creation validation completed")
    :ok
  end

  defp perform_final_validation(users, total_expenses) do
    try do
      # Verify users can be found in database
      Enum.each(users, fn user ->
        db_user = Repo.get(ExpenseTrackerApi.Accounts.User, user.id)

        unless db_user do
          raise "User #{user.email} not found in database after creation"
        end
      end)

      # Verify expenses exist in database
      user_ids = Enum.map(users, & &1.id)

      db_expense_count =
        from(e in ExpenseTrackerApi.Expenses.Expense,
          where: e.user_id in ^user_ids
        )
        |> Repo.aggregate(:count, :id)

      if db_expense_count != total_expenses do
        raise "Database expense count (#{db_expense_count}) doesn't match created count (#{total_expenses})"
      end

      # Verify data integrity
      verify_data_integrity(users)

      Logger.debug("   ✅ Final validation completed successfully")
      :ok
    rescue
      error ->
        Logger.error("   ❌ Final validation failed: #{inspect(error)}")
        reraise error, __STACKTRACE__
    end
  end

  defp verify_data_integrity(users) do
    Enum.each(users, fn user ->
      # Check that user has expenses
      expense_count =
        from(e in ExpenseTrackerApi.Expenses.Expense,
          where: e.user_id == ^user.id
        )
        |> Repo.aggregate(:count, :id)

      if expense_count == 0 do
        Logger.warning("   ⚠️  User #{user.email} has no expenses")
      end

      # Check that all expenses have valid categories
      invalid_expenses =
        from(e in ExpenseTrackerApi.Expenses.Expense,
          where: e.user_id == ^user.id and is_nil(e.category)
        )
        |> Repo.aggregate(:count, :id)

      if invalid_expenses > 0 do
        raise "User #{user.email} has #{invalid_expenses} expenses with invalid categories"
      end
    end)

    :ok
  end
end
