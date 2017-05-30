defmodule Telegram.Bot do
  use HTTPoison.Base

  @bot_endpoint "https://api.telegram.org/bot"

  def process_url(path) do
    @bot_endpoint <> token() <> "/" <> path
  end

  defp token, do: Application.get_env(:walybot, :telegram) |> Keyword.get(:bot_token)

  # convenience functions
  def get_updates do
    with {:ok, response} <- get("getUpdates"),
         %{body: body, status_code: 200} <- response,
         {:ok, data} <- Poison.decode(body),
         %{"ok" => true, "result" => updates} <- data,
    do: {:ok, updates}
  end
end
