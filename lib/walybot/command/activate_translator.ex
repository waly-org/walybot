defmodule Walybot.Command.ActivateTranslator do
  alias Walybot.Ecto.{Repo,Translator}
  import Ecto.Query
  import Walybot.Command.Helpers

  def callback(%{"data" => id_str}=query) do
    handle_callback_error(query, fn -> attempt_to_activate(query, id_str) end)
  end

  def command(update) do
    translators = Translator |> where(is_authorized: false) |> Repo.all
    prompt = "activate - select which translator you would like to activate"
    handle_command_error(update, fn -> show_translator_list_keyboard(update, translators, prompt) end)
  end

  defp attempt_to_activate(query, id_str) do
    with {:ok, translator} <- lookup_translator_by_id(id_str),
         {:ok, translator} <- activate(translator),
    do: Telegram.Bot.edit_message(query, %{text: "👍🏽 #{translator.username} has been activated"})
  end

  defp activate(translator) do
    %{is_authorized: true} |> Translator.changeset(translator) |> Repo.update
  end
end
