defmodule Walybot.Conversations do
  require Logger
  alias Walybot.{Conversation,Repo,Translation}

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

  defp create_translation(conversation, %{"message" => %{"from" => %{"username" => username}, "text" => text}}) do
    %{author: username, text: text}
    |> Translation.create_changeset(conversation)
    |> Repo.insert
  end

  defp lookup_conversation(telegram_id) do
    import Ecto.Query
    Conversation |> where(telegram_id: ^telegram_id) |> Repo.one
  end
end
