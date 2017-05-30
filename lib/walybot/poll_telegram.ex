defmodule Walybot.PollTelegram do
  use GenServer
  require Logger

  @poll_interval 5_000

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    {:ok, nil, @poll_interval}
  end

  def handle_info(:timeout, state) do
    IO.puts "go check for new updates"
    {:noreply, state, @poll_interval}
  end
  def handle_info(other, state) do
    Logger.error "#{__MODULE__} receiving unexpected message #{inspect other}"
    {:noreply, state, @poll_interval}
  end
end
