defmodule Walybot.Conversation do
  use GenServer
  require Logger
  alias Walybot.Ecto.{Conversation,Repo,User}
  alias Walybot.Update

  @translation_timeout_check_interval 1_000

  def start_link(name, conversation_id) do
    GenServer.start_link(__MODULE__, conversation_id, name: name)
  end

  def init(conversation_id) do
    Process.flag(:trap_exit, true)
    Process.send_after(self(), :translation_timeout_check, @translation_timeout_check_interval)
    {:ok, conversation} = Conversation.first_or_create(conversation_id)
    state = %{
      conversation: conversation,
      conversation_id: conversation_id,
    }
    {:ok, state}
  end

  def handle_call({:please_translate, translation}, _from, state) do
    call_switchboard(:please_translate, [translation, state], state)
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
    call_switchboard(:update, [update, state], state)
  end
  def handle_call({:user_update, user}, _from, state) do
    {:reply, :ok, Map.put(state, :user, user)}
  end

  def handle_info(:translation_timeout_check, state) do
    state = Walybot.Command.Translation.translation_timeout_check(state)
    Process.send_after(self(), :translation_timeout_check, @translation_timeout_check_interval)
    {:noreply, state}
  end
  def handle_info(other, state) do
    Logger.error("#{__MODULE__}/#{state[:conversation_id]} received unexpected message #{inspect other}")
    {:noreply, state}
  end

  defp call_switchboard(function, args, state) do
    case apply(Walybot.Switchboard, function, args) do
      {:context, new_state} -> {:reply, :ok, new_state}
      response -> {:reply, response, state}
    end
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

  def terminate(_, %{translating: true, conversation_id: conversation_id}) do
    Telegram.Bot.send_message(conversation_id, "😕 the system is being restarted, you will need to wait ~1min and then send the /translate message again to continue translating")
    :normal
  end
  def terminate(reason, state) do
    :normal
  end
end
