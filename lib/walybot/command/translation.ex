defmodule Walybot.Command.Translation do
  def command("/translate"<>_, update, %{user: %{is_translator: true}}=context) do
    with :ok <- Walybot.TranslationQueue.subscribe_to_translations(),
         {:ok, _} <- Telegram.Bot.send_message(update, "👍🏽 we will start sending you messagse to translate. When you are done, just send a /signoff message and we will stop sending you translations."),
    do: {:context, Map.put(context, :translating, true)}
  end
  def command("/translate"<>_, _, _), do: {:error, "you must be a translator"}
  def command("/signoff"<>_, update, %{user: %{is_translator: true}}=context) do
    with :ok <- Walybot.TranslationQueue.unsubscribe_from_translations(),
         {:ok, _} <- Telegram.Bot.send_message(update, "Thanks for helping to translate! We'll let you get some rest"),
    do: {:context, Map.delete(context, :translating)}
  end
  def command("/signoff"<>_, _, _), do: {:error, "you must be a translator"}

  def expecting({:translation_for, translation}, %{"message" => %{"text" => translated}}=update, %{user: user}=context) do
    with :ok <- Walybot.TranslationQueue.provide_translation(translation, translated, user),
         {:ok, _} <- Telegram.Bot.send_message(update, "👍🏽 thanks!"),
    do: {:context, Map.delete(context, :expecting)}
  end

  def please_translate(translation, %{conversation_id: conversation_id}=context) do
    with {:ok, _} <- Telegram.Bot.send_message(conversation_id, "PLEASE TRANSLATE THIS \n#{translation.text}"),
    do: {:context, Map.put(context, :expecting, {__MODULE__, {:translation_for, translation}})}
  end
end
