defmodule Walybot.Switchboard do
  require Logger

  def update(%{"message" => %{"text" => text}}=update, conversation_context) do
    Walybot.Command.Helpers.handle_command_error(update, fn ->
      text_message(text, update, conversation_context)
    end)
  end
  def update(%{"callback_query" => query}, conversation_context) do
    Walybot.Command.Helpers.handle_callback_error(query, fn ->
      callback_query(query, conversation_context)
    end)
  end
  def update(%{"message" => %{"new_chat_member" => _}}, _conversation_context), do: :ok
  def update(%{"message" => %{"left_chat_member" => _}}, _conversation_context), do: :ok
  def update(update, _conversation_context) do
    Logger.info "not sure what type of message this is #{inspect update}"
  end

  defp callback_query(%{"message" => %{"text" => "admin"<>_}}=query, context), do: Walybot.Command.Admin.callback(query, context)
  defp callback_query(query, conversation_context) do
    Logger.info "unhandled callback query: #{inspect query} (#{inspect conversation_context})"
    :ok
  end

  defp text_message("/admin"<>_, update, %{user: user}), do: Walybot.Command.Admin.command(update, user)
  defp text_message("/starttranslation"<>_, update, context), do: Walybot.Command.StartTranslation.command(update, context)
  defp text_message("/stoptranslation"<>_, update, context), do: Walybot.Command.StopTranslation.command(update, context)
  defp text_message("/translate"<>_, update, _conversation_context), do: Walybot.Command.GetTranslation.command("/translate", update)
  defp text_message(_text, update, %{expecting: {module, arg}}=context), do: apply(module, :expecting, [arg, update, context])
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
