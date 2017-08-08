defmodule Walybot.Switchboard do
  require Logger

  def update(%{"message" => %{"text" => text}}=update, conversation_context), do: text_message(text, update, conversation_context)
  def update(%{"callback_query" => query}, conversation_context), do: callback_query(query, conversation_context)
  def update(%{"message" => %{"new_chat_member" => _}}, _conversation_context), do: :ok
  def update(%{"message" => %{"left_chat_member" => _}}, _conversation_context), do: :ok
  def update(update, _conversation_context) do
    Logger.info "not sure what type of message this is #{inspect update}"
  end

  defp callback_query(%{"message" => %{"text" => "activate"<>_}}=query, _conversation_context), do: Walybot.Command.ActivateTranslator.callback(query)
  defp callback_query(%{"message" => %{"text" => "deactivate"<>_}}=query, _conversation_context), do: Walybot.Command.DeactivateTranslator.callback(query)
  defp callback_query(query, _conversation_context) do
    Logger.info "unhandled callback query: #{inspect query}"
    :ok
  end

  defp text_message("/activate"<>_, update, _conversation_context), do: Walybot.Command.ActivateTranslator.command(update)
  defp text_message("/add"<>_=command, update, _conversation_context), do: Walybot.Command.AddTranslator.command(command, update)
  defp text_message("/deactivate"<>_=command, update, _conversation_context), do: Walybot.Command.DeactivateTranslator.command(command, update)
  defp text_message("/list"<>_, update, _conversation_context), do: Walybot.Command.ListTranslators.command("/list", update)
  defp text_message("/translate"<>_, update, _conversation_context), do: Walybot.Command.GetTranslation.command("/translate", update)
  defp text_message(_, %{"message" => %{"chat" => %{"type" => "private"}}}=update, _conversation_context), do: Walybot.Command.ProvideTranslation.command("", update)
  defp text_message(_, %{"message" => %{"chat" => %{"type" => "group"}}}=update, _conversation_context) do
    Walybot.Conversations.queue_for_translation(update)
  end
  defp text_message(_, update, _conversation_context) do
    Appsignal.send_error(%RuntimeError{}, "Received unexpected text message", System.stacktrace(), %{update: update})
    # TODO: Maybe we should do some kind of 404 logic here?
    Logger.info "not sure what to do with #{inspect update}"
    :ok
  end
end
