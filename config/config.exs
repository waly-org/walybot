# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :walybot, :telegram, bot_token: System.get_env("TELEGRAM_BOT_TOKEN")
