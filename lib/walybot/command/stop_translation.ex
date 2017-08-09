defmodule Walybot.Command.StopTranslation do
  alias Walybot.Ecto.{Conversation,Repo}
  import Walybot.Command.Helpers

  def command(update, %{conversation: conversation}=context) do
    with telegram_id <- Walybot.Update.sender_id(update),
         {:ok, _user} <- lookup_admin_by_telegram_id(telegram_id),
         {:ok, conversation} <- %{needs_translation: false} |> Conversation.changeset(conversation) |> Repo.update,
         {:ok, _} <- Telegram.Bot.send_message(update, "🙅🏽 no more translating here"),
    do: {:context, Map.put(context, :conversation, conversation)}
  end
end
