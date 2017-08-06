defmodule Walybot.Conversation do
  use GenServer
  require Logger

  def start_link(name, conversation_id) do
    GenServer.start_link(__MODULE__, conversation_id, name: name)
  end

  def init(conversation_id) do
    {:ok, %{conversation_id: conversation_id}}
  end

  def handle_call({:update, update}, _from, state) do
    result = Walybot.Switchboard.update(update)
    {:reply, result, state}
  end
end
