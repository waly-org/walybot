defmodule Walybot.Conversation do
  use GenServer
  require Logger
  alias Walybot.Ecto.{Conversation,Repo,Translation,User}
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

  def handle_call({:please_translate, translation}, _from, %{conversation: %{telegram_id: telegram_id}}=state) do
    Logger.info "#{state.conversation_id} - please translate #{inspect translation}"
    {:ok, _} = Telegram.Bot.send_message(telegram_id, "PLEASE TRANSLATE =\n#{translation.text}")
    state = Map.put(state, :expecting, {__MODULE__, translation})
    {:reply, :ok, state}
  end
  def handle_call({:send_translation, text}, _from, %{conversation: %{telegram_id: telegram_id}}=state) do
    {:ok, _} = Telegram.Bot.send_message(telegram_id, text)
    {:reply, :ok, state}
  end
  def handle_call({:update, update}, _from, state) do
    Logger.info "#{state.conversation_id} - #{inspect update}"
    state = state
            |> update_conversation(update)
            |> update_user(update)
    case Walybot.Switchboard.update(update, state) do
      {:context, new_state} -> {:reply, :ok, new_state}
      response -> {:reply, response, state}
    end
  end
  def handle_call({:user_update, user}, _from, state) do
    {:reply, :ok, Map.put(state, :user, user)}
  end

  def expecting(%Translation{}=translation, %{"message" => %{"text" => translated}}, %{user: user}=context) do
    :ok = Walybot.TranslationQueue.provide_translation(translation, translated, user)
    {:context, Map.delete(context, :expecting)}
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
