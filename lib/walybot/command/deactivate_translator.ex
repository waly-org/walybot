defmodule Walybot.Command.DeaactivateTranslator do
  alias Walybot.{Repo,Translator}
  import Walybot.Command.Helpers

  def process(text, update) do
    handle_error(update, fn -> attempt_to_deactivate(text, update) end)
  end

  defp attempt_to_deactivate(text, update) do
    with {:ok, username} <- parse_username("/deactivate", text),
         {:ok, translator} <- lookup_translator(username),
         {:ok, translator} <- deactivate(translator),
         {:ok, _message} <- Telegram.Bot.send_message(update, "👍🏽 #{translator.username} has been de-activated!"),
    do: :ok
  end

  defp deactivate(translator) do
    %{is_authorized: false} |> Translator.changeset(translator) |> Repo.update
  end
end
