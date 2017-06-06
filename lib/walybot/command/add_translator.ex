defmodule Walybot.Command.AddTranslator do
  require Logger
  alias Walybot.{Repo,Translator}
  import Ecto.Query

  def process(text, update) do
    case attempt_to_add_translator(text, update) do
      :ok -> :ok
      {:error, message} ->
        case  Telegram.Bot.send_reply(update, "😢 #{message}") do
          {:ok, _message} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  def attempt_to_add_translator(text, update) do
    with {:ok, username} <- parse_username(text),
         {:ok, translator} <- create_or_update_translator(username),
         {:ok, _message} <- Telegram.Bot.send_reply(update, "👍🏽 #{translator.username} is #{active_or_deactivated(translator)}"),
    do: :ok
  end

  def parse_username("/addtranslator @"<>rest) do
    case String.split(rest) do
      [username] -> {:ok, username}
      _ -> {:error, "I din't understand that username, please make sure it is a single username like @example"}
    end
  end
  def parse_username(_), do: {:error, "please provide a username: /addtranslator @example"}

  def create_or_update_translator(username) do
    case Translator |> where(username: ^username) |> Repo.one do
      nil ->
        %{username: username, is_authorized: true} |> Translator.changeset |> Repo.insert
      translator -> {:ok, translator}
    end
  end

  defp active_or_deactivated(%{is_authorized: true}), do: "activated"
  defp active_or_deactivated(_), do: "deactivated"
end
