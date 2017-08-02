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

  def edit_message(%{"message" => %{"chat" => %{"id" => cid}, "message_id" => mid}}, message) do
    data = Map.merge(%{chat_id: cid, message_id: mid}, message)
    post_and_parse("editMessageText", data)
  end

  def send_message(%{"message" => %{"chat" => %{"id" => cid}}}, text, extra_message_options \\ %{}) do
    data = Map.merge(%{chat_id: cid, text: text}, extra_message_options) |> IO.inspect
    post_and_parse("sendMessage", data)
  end

  def send_reply(%{"message" => %{"message_id" => mid}}=update, text, extra_message_options \\ %{}) do
    options = %{reply_to_message_id: mid} |> Map.merge(extra_message_options)
    send_message(update, text, options)
  end

  def post_and_parse(method, data) do
    body = Poison.encode!(data)
    {microseconds, result} = :timer.tc(fn ->
      post(method, body, [{"Content-Type", "application/json"}])
    end)
    Appsignal.add_distribution_value("api_request_duration", microseconds / 1000.0)
    with {:ok, response} <- result,
         {:ok, parsed} <- Poison.decode(response.body),
         {:ok, successful_entity} <- validate(parsed),
    do:  {:ok, successful_entity}
  end

  defp validate(%{"ok" => true, "result" => result}), do: {:ok, result}
  defp validate(parsed) do
    error_code = Map.get(parsed, "error_code")
    description = Map.get(parsed, "description")
    if error_code == 400 && String.contains?(description, "message is not modified") do
      {:ok, :unmodified}
    else
      reason = "[#{Map.get(parsed, "error_code")}] #{Map.get(parsed, "description")}"
      {:error, reason}
    end
  end
end
