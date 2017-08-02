defmodule Walybot.Command.GetTranslation do
  alias Walybot.Translation
  import Walybot.Command.Helpers

  def command(_text, update) do
    handle_command_error(update, fn ->
      attempt_to_get_translation(update)
    end)
  end

  defp attempt_to_get_translation(%{"message" => %{"from" => %{"username" => username}}}=update) do
    force_reply = %{reply_markup: %{force_reply: true, selective: true}}

    with {:ok, translator} <- lookup_translator(username),
         :ok <- validate_translator_authorized(translator),
         {:ok, translation} <- Translation.one_pending_translation(),
         recent_translations <- Translation.recent_translations(translation),
         text <- format_translation_message(recent_translations, translation),
         {:ok, _message} <- Telegram.Bot.send_message(update, text, force_reply),
    do: :ok
  end

  defp format_translation_message(recent_translations, translation) do
    text = Enum.reduce(recent_translations, "", fn(t, str) ->
      "#{str}\n#{t.text}"
    end)
    "#{text}\n\n=> TRANSLATE THIS\n#{translation.text}"
  end

  defp validate_translator_authorized(%{is_authorized: true}), do: :ok
  defp validate_translator_authorized(_), do: {:error, "you are not allowed to translate messages"}
end
