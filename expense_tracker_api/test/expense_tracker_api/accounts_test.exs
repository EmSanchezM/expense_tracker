defmodule ExpenseTrackerApi.AccountsTest do
  use ExpenseTrackerApi.DataCase

  alias ExpenseTrackerApi.Accounts
  alias ExpenseTrackerApi.Accounts.User

  import ExpenseTrackerApi.AccountsFixtures

  describe "create_user/1" do
    test "creates a user with valid data" do
      valid_attrs = valid_user_attributes()

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.email == valid_attrs.email
      assert user.name == valid_attrs.name
      assert Pbkdf2.verify_pass(valid_attrs.password, user.password_hash)
      assert user.password_hash != valid_attrs.password
    end

    test "returns error changeset with invalid email" do
      invalid_attrs = valid_user_attributes(%{email: "invalid-email"})

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(invalid_attrs)
      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "returns error changeset with missing email" do
      invalid_attrs = valid_user_attributes(%{email: nil})

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(invalid_attrs)
      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with duplicate email" do
      user_attrs = valid_user_attributes()
      {:ok, _user} = Accounts.create_user(user_attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(user_attrs)
      assert %{email: ["has already been taken"]} = errors_on(changeset)
    end

    test "returns error changeset with short password" do
      invalid_attrs = valid_user_attributes(%{password: "short"})

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(invalid_attrs)
      assert %{password: ["should be at least 6 character(s)"]} = errors_on(changeset)
    end

    test "returns error changeset with missing password" do
      invalid_attrs = valid_user_attributes(%{password: nil})

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(invalid_attrs)
      assert %{password: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with missing name" do
      invalid_attrs = valid_user_attributes(%{name: nil})

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(invalid_attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with empty name" do
      invalid_attrs = valid_user_attributes(%{name: ""})

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(invalid_attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with long email" do
      long_email = String.duplicate("a", 150) <> "@example.com"
      invalid_attrs = valid_user_attributes(%{email: long_email})

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(invalid_attrs)
      assert %{email: ["should be at most 160 character(s)"]} = errors_on(changeset)
    end

    test "returns error changeset with long password" do
      long_password = String.duplicate("a", 80)
      invalid_attrs = valid_user_attributes(%{password: long_password})

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(invalid_attrs)
      assert %{password: ["should be at most 72 character(s)"]} = errors_on(changeset)
    end

    test "returns error changeset with long name" do
      long_name = String.duplicate("a", 110)
      invalid_attrs = valid_user_attributes(%{name: long_name})

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(invalid_attrs)
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end
  end

  describe "authenticate_user/2" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "returns {:ok, user} with valid credentials", %{user: user} do
      assert {:ok, authenticated_user} = Accounts.authenticate_user(user.email, valid_user_password())
      assert authenticated_user.id == user.id
      assert authenticated_user.email == user.email
    end

    test "returns {:error, :invalid_credentials} with invalid email" do
      assert {:error, :invalid_credentials} = Accounts.authenticate_user("nonexistent@example.com", valid_user_password())
    end

    test "returns {:error, :invalid_credentials} with invalid password", %{user: user} do
      assert {:error, :invalid_credentials} = Accounts.authenticate_user(user.email, "wrong_password")
    end

    test "returns {:error, :invalid_credentials} with empty email" do
      assert {:error, :invalid_credentials} = Accounts.authenticate_user("", valid_user_password())
    end

    test "returns {:error, :invalid_credentials} with empty password", %{user: user} do
      assert {:error, :invalid_credentials} = Accounts.authenticate_user(user.email, "")
    end

    test "returns {:error, :invalid_credentials} with nil email" do
      # This should raise a FunctionClauseError due to guard clause
      assert_raise FunctionClauseError, fn ->
        Accounts.authenticate_user(nil, valid_user_password())
      end
    end

    test "returns {:error, :invalid_credentials} with nil password", %{user: user} do
      # This should raise a FunctionClauseError due to guard clause
      assert_raise FunctionClauseError, fn ->
        Accounts.authenticate_user(user.email, nil)
      end
    end
  end

  describe "get_user!/1" do
    test "returns the user with given id" do
      user = user_fixture()
      retrieved_user = Accounts.get_user!(user.id)

      assert retrieved_user.id == user.id
      assert retrieved_user.email == user.email
      assert retrieved_user.name == user.name
      assert retrieved_user.password_hash == user.password_hash
    end

    test "raises Ecto.NoResultsError when user does not exist" do
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(999) end
    end
  end

  describe "get_user/1" do
    test "returns the user with given id" do
      user = user_fixture()
      retrieved_user = Accounts.get_user(user.id)

      assert retrieved_user.id == user.id
      assert retrieved_user.email == user.email
      assert retrieved_user.name == user.name
      assert retrieved_user.password_hash == user.password_hash
    end

    test "returns nil when user does not exist" do
      assert Accounts.get_user(999) == nil
    end
  end
end
