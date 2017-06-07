defmodule Walybot.Plug do
  use Plug.Router
  require Logger

  plug Plug.Logger
  plug Plug.Parsers, parsers: [:json],
                     json_decoder: Poison
  plug :match
  plug :dispatch

  match Application.get_env(:walybot, :webhook_endpoint) do
    case conn.body_params do
      update when is_map(update) -> instrument_webhook(conn)
      _ -> conn |> put_resp_content_type("text/plain") |> send_resp(400, "Expected an Update")
    end
  end

  match _ do
    conn |> send_resp(404, "Not Found\n")
  end

  defp instrument_webhook(conn) do
    Appsignal.increment_counter("webhooks_received", 1)
    {microseconds, value} = :timer.tc(fn ->
      process_webhook(conn)
    end)
    Appsignal.add_distribution_value("update_processing_time", microseconds / 1000.0)
    value
  end

  defp process_webhook(%{body_params: update}=conn) do
    case Walybot.Switchboard.update(update) do
      :ok -> conn |> send_resp(200, "OK")
      {:error, reason} ->
        error_attrs = %{error: reason, update: update}
        Logger.error(error_attrs)
        Appsignal.send_error(%RuntimeError{}, "Failed to process update via webhook", System.stacktrace(), error_attrs)
        conn |> send_resp(500, "Failed to process update")
    end
  end
end
