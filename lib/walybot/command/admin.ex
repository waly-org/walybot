defmodule Walybot.Command.Admin do
  import Walybot.Command.Helpers
  alias Walybot.Ecto.{Repo,User}

  def callback(query, %{is_admin: true}=user) do
    handle_callback_error(query, fn -> attempt_callback(query, user) end)
  end
  def callback(query, _user) do
    handle_callback_error(query, fn -> {:error, "you must be an admin"} end)
  end

  def command(update, user) do
    handle_command_error(update, fn -> attempt_admin(user) end)
  end

  defp attempt_admin(%{is_admin: true}=user) do
    Telegram.Bot.send_message(user.telegram_id, "admin - What do you need?", %{
      reply_markup: %{
        inline_keyboard: [
          [%{text: "list users", callback_data: "list_users"}, %{text: "cancel", callback_data: "cancel"}],
        ]
      }
    })
  end
  defp attempt_admin(_user), do: {:error, "you must be an admin to run this command"}

  def attempt_callback(%{"data" => "cancel"}=query, _user) do
    Telegram.Bot.edit_message(query, %{text: "🖖🏾 have a nice day"})
  end
  def attempt_callback(%{"data" => "list_users"}=query, _user) do
    Telegram.Bot.edit_message(query, %{text: user_list_message()})
  end
  def attempt_callback(query, _user), do: Telegram.Bot.edit_message(query, "huh?!")

  defp user_list_message do
    User |> Repo.all |> Enum.map(&user_to_line/1) |> Enum.join("\n")
  end

  defp user_to_line(%{is_admin: false, is_translator: false, username: username}), do: "@#{username}"
  defp user_to_line(%{username: username}=user) do
    tags = [ user.is_admin && "admin", user.is_translator && "translator" ]
           |> Enum.filter(&is_binary/1)
           |> Enum.join(", ")
    "@#{username} (#{tags})"
  end
end
