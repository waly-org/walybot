defmodule Walybot.Command.DeaactivateTranslator do
  alias Walybot.{Repo,Translator}
  alias Walybot.Command.AddTranslator

  def process(text, update) do
    case attempt_to_deactivate(text, update) do
      :ok -> :ok
      {:error, reason} ->
        case Telegram.Bot.send_message(update, "😢 #{reason}") do
          {:ok, _message} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp attempt_to_deactivate(text, update) do
    with {:ok, username} <- AddTranslator.parse_username("/deactivate_translator", text),
         {:ok, translator} <- lookup_translator(username),
         {:ok, translator} <- deactivate(translator),
         {:ok, _message} <- Telegram.Bot.send_message(update, "👍🏽 #{translator.username} has been de-activated!"),
    do: :ok
  end

  defp lookup_translator(username) do
    import Ecto.Query
    case Translator |> where(username: ^username) |> Repo.one do
      nil -> {:error, "@#{username} not found"}
      record -> {:ok, record}
    end
  end

  defp deactivate(translator) do
    %{is_authorized: false} |> Translator.changeset(translator) |> Repo.update
  end
end
