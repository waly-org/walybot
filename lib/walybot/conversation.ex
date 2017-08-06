defmodule Walybot.Conversation do
  use GenServer
  require Logger
  alias Walybot.Ecto.Conversation

  def start_link(name, conversation_id) do
    GenServer.start_link(__MODULE__, conversation_id, name: name)
  end

  def init(conversation_id) do
    {:ok, conversation} = Conversation.first_or_create(conversation_id)
    state = %{
      conversation: conversation,
      conversation_id: conversation_id,
    }
    {:ok, state}
  end

  def handle_call({:update, update}, _from, state) do
    result = Walybot.Switchboard.update(update)
    {:reply, result, state}
  end
end
