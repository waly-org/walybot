defmodule Walybot.Command.Helpers do
  def handle_error(update, fun) do
    case fun.() do
      :ok -> :ok
      {:error, reason} ->
        case Telegram.Bot.send_message(update, "😢 #{reason}") do
          {:ok, _message} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  def parse_username(cmd, text) do
    prefix = "#{cmd} @"
    case String.starts_with?(text, prefix) do
      true ->
        prefix_length = String.length(prefix)
        rest = String.slice(text, prefix_length, 9999)
        case String.split(rest) do
          [username] -> {:ok, username}
          _ -> {:error, "I din't understand that username, please make sure it is a single username like @example"}
        end
      false -> {:error, "please provide a usernme: #{cmd} @example"}
    end
  end
end
