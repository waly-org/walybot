defmodule Walybot.Command.AddTranslator do
  require Logger
  alias Walybot.{Repo,Translator}
  import Walybot.Command.Helpers

  def command(text, update) do
    handle_error(update, fn -> attempt_to_add_translator(text, update) end)
  end

  def attempt_to_add_translator(text, update) do
    with {:ok, username} <- parse_username("/add", text),
         {:ok, translator} <- create_or_update_translator(username),
         {:ok, _message} <- Telegram.Bot.send_reply(update, "👍🏽 #{translator.username} is #{active_or_deactivated(translator)}"),
    do: :ok
  end

  def create_or_update_translator(username) do
    import Ecto.Query
    case Translator |> where(username: ^username) |> Repo.one do
      nil ->
        %{username: username, is_authorized: true} |> Translator.changeset |> Repo.insert
      translator -> {:ok, translator}
    end
  end

  defp active_or_deactivated(%{is_authorized: true}), do: "activated"
  defp active_or_deactivated(_), do: "deactivated"
end
