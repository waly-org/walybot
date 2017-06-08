defmodule Walybot.Command.Helpers do
  import Ecto.Query
  alias Walybot.{Repo,Translator}

  def handle_callback_error(query, fun) do
    case fun.() do
      :ok -> :ok
      {:ok, _data} -> :ok
      {:error, reason} ->
        case Telegram.Bot.edit_message(query, "😢 #{reason}") do
          {:ok, _message} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  def handle_command_error(update, fun) do
    case fun.() do
      :ok -> :ok
      {:ok, _data} -> :ok
      {:error, reason} ->
        case Telegram.Bot.send_message(update, "😢 #{reason}") do
          {:ok, _message} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  def lookup_translator_by_id(str) when is_binary(str), do: str |> String.to_integer |> lookup_translator_by_id
  def lookup_translator_by_id(id) do
    import Ecto.Query
    case Translator |> where(id: ^id) |> Repo.one do
      nil -> {:error, "translator not found"}
      translator -> {:ok, translator}
    end
  end

  def lookup_translator(username) do
    case Translator |> where(username: ^username) |> Repo.one do
      nil -> {:error, "@#{username} not found"}
      record -> {:ok, record}
    end
  end

  def parse_username(cmd, text) do
    prefix = "#{cmd} @"
    case String.starts_with?(text, prefix) do
      true ->
        prefix_length = String.length(prefix)
        rest = String.slice(text, prefix_length, 9999)
        case String.split(rest) do
          [username] -> {:ok, username}
          _ -> {:error, "I din't understand that username, please make sure it is a single username like @example"}
        end
      false -> {:error, "please provide a usernme: #{cmd} @example"}
    end
  end

  def show_translator_list_keyboard(update) do
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
end
