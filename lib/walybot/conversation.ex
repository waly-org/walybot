defmodule Walybot.Conversation do
  use GenServer
  require Logger
  alias Walybot.Ecto.{Conversation,Repo,User}
  alias Walybot.Update

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
    state = state
            |> update_conversation(update)
            |> update_user(update)
    result = Walybot.Switchboard.update(update, state)
    {:reply, result, state}
  end

  defp update_conversation(state, update) do
    {:ok, conversation} = %{name: Update.conversation_name(update)}
                          |> Conversation.changeset(state.conversation)
                          |> Repo.update
    Map.put(state, :conversation, conversation)
  end

  defp update_user(state, %{"message" => %{"chat" => %{"type" => "private", "id" => user_id, "username" => username}}}) do
    {:ok, user} = case state[:user] do
                    nil -> User.first_or_create(user_id, username)
                    user -> {:ok, user}
                  end
    {:ok, user} = %{username: username, telegram_id: user_id} |> User.changeset(user) |> Repo.update
    Map.put(state, :user, user)
  end
  defp update_user(state, _update), do: state
end
