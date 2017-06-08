defmodule Walybot.Switchboard do
  @moduledoc """
  This is the main ingestion point for updates that we receive from telegram.
  The key interface is the `update/1` function which takes a parsed update map
  and returns `:ok` or `{:error, reason}`

  Returning `:ok` should cause us to acknowledge an update so telegram can forget about it.
  Returning `{:error, reason}` should skip acknowledging so telegram will try to send it again.

  So `{:error, reason}` should not be returned for things like an invalid command. In those cases
  we should send a message back to the telegram user and report `:ok`.
  If we fail to send the reply, then we would return an `{:error, reason}` since we need to try it again.
  """

  require Logger

  def update(%{"message" => %{"text" => text}}=update), do: text_message(text, update)
  def update(update) do
    Logger.info "not sure what to do with #{inspect update}"
  end

  defp text_message("/activate"<>_=command, update), do: Walybot.Command.ActivateTranslator.process(command, update)
  defp text_message("/add"<>_=command, update), do: Walybot.Command.AddTranslator.process(command, update)
  defp text_message("/deactivate"<>_=command, update), do: Walybot.Command.DeaactivateTranslator.process(command, update)
  defp text_message("/list"<>_, update), do: Walybot.Command.ListTranslators.process("/listtranslators", update)
  defp text_message(_, %{"message" => %{"chat" => %{"type" => "private"}}}=update) do
    Logger.info "#{inspect update}"
    case Telegram.Bot.send_message(update, "😕 Sorry, I don't understand⁇") do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
  defp text_message(_, update) do
    # TODO: Maybe we should do some kind of 404 logic here?
    Logger.info "not sure what to do with #{inspect update}"
    :ok
  end
end
