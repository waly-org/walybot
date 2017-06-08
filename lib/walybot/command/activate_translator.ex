defmodule Walybot.Command.ActivateTranslator do
  alias Walybot.{Repo,Translator}
  import Walybot.Command.Helpers

  def process(text, update) do
    handle_error(update, fn -> attempt_to_activate(text, update) end)
  end

  def attempt_to_activate(text, update) do
    with {:ok, username} <- parse_username("/activate", text),
         {:ok, translator} <- lookup_translator(username),
         {:ok, translator} <- activate(translator),
         {:ok, _message} <- Telegram.Bot.send_message(update, "👍🏽 #{translator.username} has been activated!"),
    do: :ok
  end

  def activate(translator) do
    %{is_authorized: true} |> Translator.changeset(translator) |> Repo.update
  end
end
