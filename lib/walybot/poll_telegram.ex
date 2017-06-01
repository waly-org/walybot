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
    Telegram.Bot.process_all_outstanding_updates(&process_update/1)
    {:noreply, state, @poll_interval}
  end
  def handle_info(other, state) do
    Logger.error "#{__MODULE__} receiving unexpected message #{inspect other}"
    {:noreply, state, @poll_interval}
  end

  def process_update(%{"message" => %{"text" => text}}=update) do
    Logger.info "replying to #{text}"
    Telegram.Bot.send_reply(update, "TODO: translate this")
  end
  def process_update(update) do
    Logger.info "not sure what to do with this #{inspect update}"
  end
end
