defmodule Walybot.Conversations do
  @moduledoc """
  This is the main ingestion point for updates that we receive from telegram.
  The key interface is the `update/1` function which takes a parsed update map
  and returns `:ok` or `{:error, reason}`

  Returning `:ok` should cause us to acknowledge an update so telegram can forget about it.
  Returning `{:error, reason}` should skip acknowledging so telegram will try to send it again.

  So `{:error, reason}` should not be returned for things like an invalid command. In those cases
  we should send a message back to the telegram user and report `:ok`.
  If we fail to send the reply, then we would return an `{:error, reason}` since we need to try it again.
  """

  require Logger
  alias Walybot.Ecto.{Conversation,Repo,Translation}

  def queue_for_translation(update) do
    with conversation_id <- get_in(update, ["message","chat","id"]),
         %Conversation{needs_translation: true}=conversation <- lookup_conversation(conversation_id),
         {:ok, _translation} <- create_translation(conversation, update) do
      :ok
    else
      nil -> :ok
      %Conversation{} -> :ok
      {:error, _changeset} -> {:error, "failed to create translation"}
    end
  end

  def update(update) do
    case get_conversation_id(update) do
      nil -> log_error(update)
      id -> send_to_conversation(id, {:update, update})
    end
  end

  def user_update(%{telegram_id: nil}), do: :ok
  def user_update(%{telegram_id: conversation_id}=user) do
    send_to_conversation(conversation_id, {:user_update, user})
  end

  defp create_translation(conversation, %{"message" => %{"from" => %{"username" => username}, "text" => text}}) do
    %{author: username, text: text}
    |> Translation.create_changeset(conversation)
    |> Repo.insert
  end

  defp get_conversation_id(update) do
    get_in(update, ["message", "chat", "id"]) || get_in(update, ["callback_query","message", "chat", "id"])
  end

  defp log_error(update) do
    Appsignal.send_error(%RuntimeError{}, "Received unexpected text message", System.stacktrace(), %{update: update})
    Logger.info "not sure what to do with #{inspect update}"
    :ok
  end

  defp lookup_conversation(telegram_id) do
    import Ecto.Query
    Conversation |> where(telegram_id: ^telegram_id) |> Repo.one
  end

  defp send_to_conversation(conversation_id, message) do
    atom = :"CONVERSATION_#{conversation_id}"
    {:ok, pid} = case Process.whereis(atom) do
                    nil -> Walybot.ConversationSupervisor.start(atom, conversation_id)
                    pid -> {:ok, pid}
                  end
    GenServer.call(pid, message)
  end
end
