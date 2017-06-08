defmodule Walybot.Command.ListTranslators do
  alias Walybot.{Repo,Translator}

  def command(_text, update) do
    translators = Translator |> Repo.all |> Enum.group_by(fn(translator) -> translator.is_authorized end)
    msg = [
      "== active translators\n",
      translators_to_string(translators[true]),
      "\n== de-activated translators\n",
      translators_to_string(translators[false]),
    ] |> IO.iodata_to_binary
    case Telegram.Bot.send_message(update, msg) do
      {:ok, _message} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp translators_to_string(nil), do: "**none**"
  defp translators_to_string([]), do: "**none**"
  defp translators_to_string(list) do
    list |> Enum.map(fn(t) -> "* #{t.username}" end) |> Enum.join("\n")
  end
end
