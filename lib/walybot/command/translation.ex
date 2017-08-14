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

  def expecting(%{translation: translation}, %{"message" => %{"text" => translated}}=update, %{user: user}=context) do
    with :ok <- Walybot.TranslationQueue.provide_translation(translation, translated, user),
         {:ok, _} <- Telegram.Bot.send_message(update, "👍🏽 thanks!"),
    do: {:context, Map.delete(context, :expecting)}
  end

  def please_translate(translation, %{conversation_id: conversation_id}=context) do
    with {:ok, _} <- Telegram.Bot.send_message(conversation_id, "PLEASE TRANSLATE THIS \n#{translation.text}"),
         timeout_after <- (DateTime.utc_now |> DateTime.to_unix) + 300, # 5 minutes from now
    do: {:context, Map.put(context, :expecting, {__MODULE__, %{translation: translation, timeout_after: timeout_after}})}
  end

  # Note: called directly from the GenServer so we return a bare state
  # Maybe I should pass this through the switchoard to keep the same contract?
  # The only problem is that this is part of a handle_info instead of a handle_call
  # so it can't result in a {:reply, _, _} value...
  def translation_timeout_check(%{expecting: {__MODULE__, %{timeout_after: timestamp}}}=state) do
    now = DateTime.utc_now |> DateTime.to_unix
    if timestamp < now do
      with :ok <- Walybot.TranslationQueue.unsubscribe_from_translations(),
           {:ok, _} <- Telegram.Bot.send_message(state[:conversation_id], "Nevermind, it looks like you are busy. I'll pause your translations until you are ready. Just send /translate again to start."),
      do: Map.delete(state, :expecting)
    else
      state
    end
  end
  def translation_timeout_check(state), do: state
end
