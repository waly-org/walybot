defmodule Walybot.Command.ProvideTranslation do
  import Walybot.Command.Helpers
  alias Walybot.Ecto.{Conversation,Repo,Translation}
  alias Walybot.ExpectedTranslations

  def command(_text, update) do
    handle_command_error(update, fn ->
      attempt_to_set_translation(update)
    end)
  end

  def attempt_to_set_translation(%{"message" => %{"from" => %{"username" => username}, "text" => text}}) do
    with {:ok, translator} <- lookup_translator(username),
         {:ok, translation} <- ExpectedTranslations.expected_translation(translator),
         {:ok, _changeset} <- translation |> Translation.update_changeset(translator, text) |> Repo.update,
         conversation <- Repo.get(Conversation, translation.conversation_id),
         {:ok, _message} <- Telegram.Bot.send_message(conversation.telegram_id, text),
         :ok <- ExpectedTranslations.clear_expectation(translator),
    do: :ok
  end
end
