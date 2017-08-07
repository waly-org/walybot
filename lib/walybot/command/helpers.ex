defmodule Walybot.Command.Helpers do
  import Ecto.Query
  alias Walybot.Ecto.{Repo,User}

  def handle_callback_error(query, fun) do
    case fun.() do
      :ok -> :ok
      {:ok, _data} -> :ok
      {:error, reason} ->
        reason = error_message(reason)
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
        reason = error_message(reason)
        case Telegram.Bot.send_message(update, "😢 #{reason}") do
          {:ok, _message} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  def error_message(%Ecto.Changeset{}=changeset) do
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
  def error_message(reason), do: reason

  def lookup_translator_by_id(str) when is_binary(str), do: str |> String.to_integer |> lookup_translator_by_id
  def lookup_translator_by_id(id) do
    import Ecto.Query
    case Translator |> where(id: ^id) |> Repo.one do
      nil -> {:error, "translator not found"}
      translator -> {:ok, translator}
    end
  end

  def lookup_translator(username) do
    case User |> where(username: ^username, is_translator: true) |> Repo.one do
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

  def show_translator_list_keyboard(update, translators, prompt) do
    translator_buttons = translators
                         |> Enum.map(fn(t) -> %{text: "@#{t.username}", callback_data: Integer.to_string(t.id)} end)
                         |> Enum.chunk(3, 3, [nil, nil, nil])
                         |> Enum.map(fn(buttons) ->
                           Enum.filter(buttons, &( !is_nil(&1) ))
                         end)

    case translator_buttons do
      [] -> Telegram.Bot.send_message(update, "no translators available 🎉🤖")
      _ ->
        message_options = %{
          reply_markup: %{
            inline_keyboard: translator_buttons
          }
        }
        Telegram.Bot.send_message(update, prompt, message_options)
    end
  end
end
