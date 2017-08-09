defmodule Walybot.Command.Helpers do
  import Ecto.Query
  alias Walybot.Ecto.{Repo,User}

  def custom_keyboard(button_pairs) do
    buttons = button_pairs
              |> Enum.map(fn({key, label}) -> %{text: label, callback_data: key} end)
              |> group_buttons_into_rows_of_three
    %{
      reply_markup: %{
        inline_keyboard: buttons
      }
    }
  end

  def group_buttons_into_rows_of_three(buttons) do
    buttons
    |> Enum.chunk(3, 3, [nil, nil, nil])
    |> Enum.map(fn(buttons) ->
      Enum.filter(buttons, &( !is_nil(&1) ))
    end)
  end

  def lookup_admin_by_telegram_id(id) do
    case User |> where(telegram_id: ^id, is_admin: true) |> Repo.one do
      nil -> {:error, "must be admin"}
      user -> {:ok, user}
    end
  end

  def lookup_translator_by_id(str) when is_binary(str), do: str |> String.to_integer |> lookup_translator_by_id
  def lookup_translator_by_id(id) do
    case User |> where(id: ^id) |> Repo.one do
      nil -> {:error, "translator not found"}
      translator -> {:ok, translator}
    end
  end

  def parse_username(prefix, text) do
    case String.starts_with?(text, prefix) do
      true ->
        prefix_length = String.length(prefix)
        rest = String.slice(text, prefix_length, 9999)
        case String.split(rest) do
          [username] -> {:ok, username}
          _ -> {:error, "I din't understand that username, please make sure it is a single username like @example"}
        end
      false -> {:error, "please provide a username: #{prefix}example"}
    end
  end
end
