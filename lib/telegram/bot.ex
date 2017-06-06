defmodule Telegram.Bot do
  use HTTPoison.Base

  @bot_endpoint "https://api.telegram.org/bot"

  def process_url(path) do
    @bot_endpoint <> token() <> "/" <> path
  end

  defp token, do: Application.get_env(:walybot, :telegram) |> Keyword.get(:bot_token)

  # convenience functions
  def get_updates(offset \\ 0) do
    with {:ok, response} <- get("getUpdates", [], params: [offset: offset]),
         %{body: body, status_code: 200} <- response,
         {:ok, data} <- Poison.decode(body),
         %{"ok" => true, "result" => updates} <- data,
    do: {:ok, updates}
  end

  def process_all_outstanding_updates(fun), do: process_all_outstanding_updates(fun, 0)
  def process_all_outstanding_updates(fun, offset) do
    case get_updates(offset) do
      {:ok, []} -> :ok
      {:ok, updates} ->
        Enum.map(updates, fun)
        max_update_id = updates |> Enum.map(fn(%{"update_id" => id}) -> id end) |> Enum.max
        process_all_outstanding_updates(fun, max_update_id + 1)
    end
  end

  def send_message(%{"message" => %{"chat" => %{"id" => cid}}}, text) do
    data = %{chat_id: cid, text: text}
    body = Poison.encode!(data)
    post("sendMessage", body, [{"Content-Type", "application/json"}])
  end

  def send_reply(%{"message" => %{"message_id" => mid, "chat" => %{"id" => cid}}}, text) do
    data = %{chat_id: cid, text: text, reply_to_message_id: mid}
    body = Poison.encode!(data)
    post("sendMessage", body, [{"Content-Type", "application/json"}])
  end
end
