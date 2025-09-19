defmodule ExpenseTrackerApiWeb.Schemas.AuthSchema do
  @moduledoc """
  OpenAPI schemas for Authentication-related endpoints
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  defmodule User do
    @moduledoc "Schema for User model"

    OpenApiSpex.schema(%{
      title: "User",
      description: "A user account",
      type: :object,
      properties: %{
        id: %Schema{
          type: :integer,
          description: "Unique identifier for the user",
          example: 1
        },
        email: %Schema{
          type: :string,
          format: :email,
          description: "User's email address",
          maxLength: 160,
          example: "user@example.com"
        },
        name: %Schema{
          type: :string,
          description: "User's full name",
          minLength: 1,
          maxLength: 100,
          example: "John Doe"
        },
        inserted_at: %Schema{
          type: :string,
          format: :"date-time",
          description: "Timestamp when the user was created",
          example: "2024-01-15T10:30:00Z"
        },
        updated_at: %Schema{
          type: :string,
          format: :"date-time",
          description: "Timestamp when the user was last updated",
          example: "2024-01-15T10:30:00Z"
        }
      },
      required: [:id, :email, :name],
      example: %{
        id: 1,
        email: "user@example.com",
        name: "John Doe",
        inserted_at: "2024-01-15T10:30:00Z",
        updated_at: "2024-01-15T10:30:00Z"
      }
    })
  end

  defmodule LoginRequest do
    @moduledoc "Schema for login request"

    OpenApiSpex.schema(%{
      title: "LoginRequest",
      description: "Request body for user login",
      type: :object,
      properties: %{
        email: %Schema{
          type: :string,
          format: :email,
          description: "User's email address",
          example: "user@example.com"
        },
        password: %Schema{
          type: :string,
          description: "User's password",
          minLength: 6,
          maxLength: 72,
          example: "password123"
        }
      },
      required: [:email, :password],
      example: %{
        email: "user@example.com",
        password: "password123"
      }
    })
  end

  defmodule JWTToken do
    @moduledoc "Schema for JWT token structure"

    OpenApiSpex.schema(%{
      title: "JWTToken",
      description: "JWT authentication token",
      type: :object,
      properties: %{
        token: %Schema{
          type: :string,
          description: "JWT bearer token for authentication",
          example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        },
        user: User
      },
      required: [:token, :user],
      example: %{
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
        user: %{
          id: 1,
          email: "user@example.com",
          name: "John Doe"
        }
      }
    })
  end

  defmodule LoginResponse do
    @moduledoc "Schema for login response"

    OpenApiSpex.schema(%{
      title: "LoginResponse",
      description: "Response containing JWT token and user data after successful login",
      type: :object,
      properties: %{
        data: JWTToken,
        message: %Schema{
          type: :string,
          description: "Success message",
          example: "Login successful"
        }
      },
      required: [:data],
      example: %{
        data: %{
          token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
          user: %{
            id: 1,
            email: "user@example.com",
            name: "John Doe"
          }
        },
        message: "Login successful"
      }
    })
  end

  defmodule RegisterRequest do
    @moduledoc "Schema for user registration request"

    OpenApiSpex.schema(%{
      title: "RegisterRequest",
      description: "Request body for user registration",
      type: :object,
      properties: %{
        user: %Schema{
          type: :object,
          description: "User registration data",
          properties: %{
            email: %Schema{
              type: :string,
              format: :email,
              description: "User's email address",
              maxLength: 160,
              example: "newuser@example.com"
            },
            password: %Schema{
              type: :string,
              description: "User's password",
              minLength: 6,
              maxLength: 72,
              example: "securepassword123"
            },
            name: %Schema{
              type: :string,
              description: "User's full name",
              minLength: 1,
              maxLength: 100,
              example: "Jane Smith"
            }
          },
          required: [:email, :password, :name]
        }
      },
      required: [:user],
      example: %{
        user: %{
          email: "newuser@example.com",
          password: "securepassword123",
          name: "Jane Smith"
        }
      }
    })
  end

  defmodule RegisterResponse do
    @moduledoc "Schema for user registration response"

    OpenApiSpex.schema(%{
      title: "RegisterResponse",
      description: "Response containing user data after successful registration",
      type: :object,
      properties: %{
        data: User,
        message: %Schema{
          type: :string,
          description: "Success message",
          example: "User registered successfully"
        }
      },
      required: [:data],
      example: %{
        data: %{
          id: 2,
          email: "newuser@example.com",
          name: "Jane Smith",
          inserted_at: "2024-01-15T10:30:00Z",
          updated_at: "2024-01-15T10:30:00Z"
        },
        message: "User registered successfully"
      }
    })
  end
end
