defmodule Walybot.Command.ActivateTranslator do
  alias Walybot.{Repo,Translator}
  import Walybot.Command.Helpers

  def callback(%{"data" => id_str}=query) do
    case attempt_to_activate(query, id_str) do
      :ok -> :ok
      {:ok, _message} -> :ok
      {:error, reason} ->
        case Telegram.Bot.edit_message(query, "😢 #{reason}") do
          {:ok, _message} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  def command(update) do
    handle_error(update, fn -> show_translator_list_keyboard(update) end)
  end

  defp show_translator_list_keyboard(update) do
    import Ecto.Query
    translator_buttons = Translator
                         |> where(is_authorized: false)
                         |> Repo.all
                         |> Enum.map(fn(t) -> %{text: "@#{t.username}", callback_data: Integer.to_string(t.id)} end)
                         |> Enum.chunk(3, 3, [nil, nil, nil])
                         |> Enum.map(fn(buttons) ->
                           Enum.filter(buttons, &( !is_nil(&1) ))
                         end)

    case translator_buttons do
      [] -> Telegram.Bot.send_message(update, "all translators are active 🎉🤖")
      _ ->
        message_options = %{
          reply_markup: %{
            inline_keyboard: translator_buttons
          }
        }
        Telegram.Bot.send_message(update, "activate - select which translator you want to activate", message_options)
    end
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
