defmodule Walybot.PollTelegram do
  use GenServer
  require Logger

  @poll_interval 1_000

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

  def process_update(update) do
    # TODO: instead of raising an exception when we get {:error, reason}, we need a graceful way of telling
    # the poller to stop and give up?
    :ok = Walybot.Switchboard.update(update)
  end
end
