defmodule Walybot.ConversationSupervisor do
  use Supervisor

  def start_link(:ok) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Walybot.Conversation, [], restart: :transient),
    ]
    supervise(children, strategy: :simple_one_for_one)
  end

  def start(registered_name, conversation_id) do
    Supervisor.start_child(__MODULE__, [registered_name, conversation_id])
  end
end
