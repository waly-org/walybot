defmodule Walybot.Plug do
  import Plug.Conn

  def init(_opts) do
    Application.get_env(:walybot, :webhook_endpoint)
  end

  def call(%{request_path: endpoint}=conn, endpoint) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Got It")
  end

  def call(conn, _endpoint) do
    conn |> put_resp_content_type("text/plain") |> send_resp(404, "Not Found")
  end
end
