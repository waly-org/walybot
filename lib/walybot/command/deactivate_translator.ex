defmodule Walybot.Command.DeactivateTranslator do
  alias Walybot.Ecto.{Repo,Translator}
  import Ecto.Query
  import Walybot.Command.Helpers

  def callback(%{"data" => id_str}=query) do
    handle_callback_error(query, fn -> attempt_to_deactivate(query, id_str) end)
  end

  def command(_text, update) do
    translators = Translator |> where(is_authorized: true) |> Repo.all
    prompt = "deactivate - select which translator you would like to de-activate"
    handle_command_error(update, fn -> show_translator_list_keyboard(update, translators, prompt) end)
  end

  defp attempt_to_deactivate(query, id_str) do
    with {:ok, translator} <- lookup_translator_by_id(id_str),
         {:ok, translator} <- deactivate(translator),
         {:ok, _message} <- Telegram.Bot.edit_message(query, %{text: "👍🏽 #{translator.username} has been de-activated"}),
    do: :ok
  end

  defp deactivate(translator) do
    %{is_authorized: false} |> Translator.changeset(translator) |> Repo.update
  end
end
