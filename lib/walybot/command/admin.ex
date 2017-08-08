defmodule Walybot.Command.Admin do
  import Walybot.Command.Helpers
  alias Walybot.Ecto.{Repo,User}

  @admin_buttons [
    {"list_users", "list users"},
    {"add_translator", "add translator"},
    {"remove_translator", "remove translator"},
    {"cancel", "cancel"},
  ]

  def callback(_query, %{user: %{is_admin: false}}), do: {:error, "you must be an admin"}
  def callback(%{"data" => "add_translator"}=query, context) do
    case Telegram.Bot.edit_message(query, %{text: "cool, send me their username"}) do
      {:ok, _} -> {:context, Map.put(context, :expecting, {__MODULE__, "add_translator"})}
      other -> other
    end
  end
  def callback(%{"data" => "cancel"}=query, _context) do
    Telegram.Bot.edit_message(query, %{text: "🖖🏾 have a nice day"})
  end
  def callback(%{"data" => "list_users"}=query, _context) do
    Telegram.Bot.edit_message(query, %{text: user_list_message()})
  end
  def callback(query, _context), do: Telegram.Bot.edit_message(query, %{text: "huh?!"})

  def command(_update, %{is_admin: true}=user) do
    Telegram.Bot.send_message(user.telegram_id, "admin - What do you need?", custom_keyboard(@admin_buttons))
  end
  def command(_update, _user), do: {:error, "you must be an admin to run this command"}

  def expecting("add_translator", %{"message" => %{"text" => text}}=update, context) do
    with {:ok, username} <- parse_username("@", text),
         {:ok, user} <- User.first_or_create(username),
         {:ok, user} <- %{is_translator: true} |> User.changeset(user) |> Repo.update,
         {:ok, _} <- Telegram.Bot.send_message(update, "👍🏽 #{user.username} is now a translator"),
    do: {:context, Map.delete(context, :expecting)}
  end

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
