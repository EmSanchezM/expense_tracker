#!/usr/bin/env elixir

# Script to generate environment variables for development
# Run with: elixir scripts/setup_env.exs

defmodule EnvSetup do
  def generate_secret_key_base do
    :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64)
  end

  def generate_guardian_secret do
    :crypto.strong_rand_bytes(32) |> Base.encode64() |> binary_part(0, 32)
  end

  def create_env_file do
    secret_key_base = generate_secret_key_base()
    guardian_secret = generate_guardian_secret()

    env_content = """
    # Database Configuration
    DATABASE_URL=ecto://postgres:postgres@localhost/expense_tracker_api_dev

    # Server Configuration
    PORT=4000
    PHX_HOST=localhost
    PHX_SERVER=true

    # Security Keys (Generated automatically)
    SECRET_KEY_BASE=#{secret_key_base}
    GUARDIAN_SECRET_KEY=#{guardian_secret}

    # CORS Configuration
    CORS_ORIGINS=http://localhost:3000,http://localhost:5173,http://localhost:8080

    # Database Pool
    POOL_SIZE=10

    # Environment
    MIX_ENV=dev
    """

    File.write!(".env", env_content)
    IO.puts("✅ Generated .env file with new secret keys!")
    IO.puts("📝 You can modify the values in .env as needed.")
  end

  def run do
    if File.exists?(".env") do
      IO.puts("⚠️  .env file already exists!")
      IO.write("Do you want to overwrite it? (y/N): ")

      case IO.read(:line) |> String.trim() |> String.downcase() do
        "y" -> create_env_file()
        "yes" -> create_env_file()
        _ -> IO.puts("❌ Cancelled. Existing .env file preserved.")
      end
    else
      create_env_file()
    end
  end
end

EnvSetup.run()
