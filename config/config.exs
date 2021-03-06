# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

postgres_ssl = System.get_env("POSTGRES_SSL") == "TRUE"
config :walybot, Walybot.Ecto.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: System.get_env("POSTGRES_DB") || "walybot_#{Mix.env}",
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD"),
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  pool_size: 3,
  ssl: postgres_ssl

if Mix.env == :test do
  config :logger, level: :warn
end

config :walybot, ecto_repos: [Walybot.Ecto.Repo]

config :walybot, webhook_endpoint: System.get_env("WEBHOOK_ENDPOINT") || "/webhook"

bot_token = case System.get_env("TELEGRAM_BOT_TOKEN") do
              nil ->
                case File.read(".telegram_bot_token") do
                  {:ok, str} -> str |> String.trim
                  {:error, _reason} -> "DEFAULT_BOT_TOKEN"
                end
              str -> str
            end
config :walybot, :telegram, bot_token: bot_token

# Import Timber, structured logging
import_config "timber.exs"
