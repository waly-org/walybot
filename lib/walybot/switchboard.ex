defmodule Walybot.Switchboard do
  require Logger

  def please_translate(translation, %{conversation: %{telegram_id: conversation_id}}=context) do
    handle_command_error(conversation_id, fn ->
      Walybot.Command.Translation.please_translate(translation, context)
    end)
  end

  def update(%{"message" => %{"text" => text}}=update, conversation_context) do
    handle_command_error(update, fn ->
      text_message(text, update, conversation_context)
    end)
  end
  def update(%{"callback_query" => query}, conversation_context) do
    handle_callback_error(query, fn ->
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

  defp text_message("/translate"<>_, update, context), do: Walybot.Command.Translation.command("/translate", update, context)
  defp text_message("/signoff"<>_, update, context), do: Walybot.Command.Translation.command("/signoff", update, context)
  defp text_message("/admin"<>_, update, %{user: user}), do: Walybot.Command.Admin.command(update, user)
  defp text_message("/starttranslation"<>_, update, context), do: Walybot.Command.StartTranslation.command(update, context)
  defp text_message("/stoptranslation"<>_, update, context), do: Walybot.Command.StopTranslation.command(update, context)
  defp text_message(_text, update, %{expecting: {module, arg}}=context), do: apply(module, :expecting, [arg, update, context])
  defp text_message(_, update, %{conversation: %{needs_translation: true}=conversation}) do
    Walybot.TranslationQueue.request_translation(update,conversation)
  end
  defp text_message(_, update, _conversation_context) do
    Appsignal.send_error(%RuntimeError{}, "Received unexpected text message", System.stacktrace(), %{update: "#{inspect update}"})
    # TODO: Maybe we should do some kind of 404 logic here?
    Logger.info "not sure what to do with #{inspect update}"
    :ok
  end

  defp handle_callback_error(query, fun) do
    case fun.() do
      :ok -> :ok
      {:ok, _data} -> :ok
      {:context, new_context} -> {:context, new_context}
      {:error, reason} ->
        reason = error_message(reason)
        case Telegram.Bot.edit_message(query, %{text: "😢 #{reason}"}) do
          {:ok, _message} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp handle_command_error(update, fun) do
    case fun.() do
      :ok -> :ok
      {:ok, _data} -> :ok
      {:context, new_context} -> {:context, new_context}
      {:error, reason} ->
        reason = error_message(reason)
        case Telegram.Bot.send_message(update, "😢 #{reason}") do
          {:ok, _message} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp error_message(%Ecto.Changeset{}=changeset) do
    import Ecto.Changeset, only: [traverse_errors: 2]
    changeset
    |> traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn({key, messages}) ->
      "#{key}: #{Enum.join(messages, ", ")}"
    end)
    |> Enum.join(", ")
  end
  defp error_message(reason), do: reason
end
