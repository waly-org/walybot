defmodule Walybot.Plug do
  use Plug.Router

  plug Plug.Logger
  plug Plug.Parsers, parsers: [:json],
                     json_decoder: Poison
  plug :match
  plug :dispatch

  match Application.get_env(:walybot, :webhook_endpoint) do
    conn |> put_resp_content_type("text/plain") |> send_resp(200, "Got It!\n")
  end

  match _ do
    conn |> send_resp(404, "Not Found\n")
  end
end
