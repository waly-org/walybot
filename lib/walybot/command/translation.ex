defmodule Walybot.Command.Translation do
  def command("/translate"<>_, update, %{user: %{is_translator: true}}) do
    with :ok <- Walybot.TranslationQueue.subscribe_to_translations(),
         {:ok, _} <- Telegram.Bot.send_message(update, "👍🏽 we will start sending you message to translate. When you are done, just send a /signoff message and we will stop sending you translations."),
    do: :ok
  end
  def command("/translate"<>_, _, _), do: {:error, "you must be a translator"}
  def command("/signoff"<>_, update, %{user: %{is_translator: true}}) do
    with :ok <- Walybot.TranslationQueue.unsubscribe_from_translations(),
         {:ok, _} <- Telegram.Bot.send_message(update, "Thanks for helping to translate! We'll let you get some rest"),
    do: :ok
  end
  def command("/signoff"<>_, _, _), do: {:error, "you must be a translator"}
end
