# Expense tracker API

## Description
API for an expense tracker application. This API should allow users to create, read, update, and delete expenses. Users should be able to sign up and log in to the application. Each user should have their own set of expenses.

## Features
Here are the features that you should implement in your Expense Tracker API:

* Sign up as a new user.
* Generate and validate JWTs for handling authentication and user session.
* List and filter your past expenses. You can add the following filters:
* Past week
* Past month
* Last 3 months
* Custom (to specify a start and end date of your choosing).
* Add a new expense
* Remove existing expenses
* Update existing expenses

## Constraints

You can use any programming language and framework of your choice. You can use a database of your choice to store the data. You can use any ORM or database library to interact with the database.

Here are some constraints that you should follow:

You’ll be using JWT (JSON Web Token) to protect the endpoints and to identify the requester.
For the different expense categories, you can use the following list (feel free to decide how to implement this as part of your data model):
* Groceries
* Leisure
* Electronics
* Utilities
* Clothing
* Health
* Others

## References

Description project: [Roadmap.sh Backend](https://roadmap.sh/projects/expense-tracker-api).

## Getting started

### Environment Setup

1. **Configure environment variables:**
   ```bash
   # Generate .env file with secure keys
   elixir scripts/setup_env.exs
   
   # Or copy and edit manually
   cp .env.example .env
   ```

2. **Install dependencies:**
   ```bash
   cd expense_tracker_api
   mix deps.get
   ```

3. **Setup database:**
   ```bash
   mix ecto.setup
   ```

### Running the Application

**Development with Docker:**
```bash
docker-compose -f compose.dev.yml up
```

**Development locally:**
```bash
cd expense_tracker_api
mix phx.server
```

**Enable API documentation with Open API**
```bash
# Enable API documentation in production
export ENABLE_API_DOCS=true

# Or in your .env file
ENABLE_API_DOCS=true
```

The API will be available at `http://localhost:4000`