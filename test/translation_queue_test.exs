defmodule Walybot.TranslationQueueTest do
  use ExUnit.Case
  alias Walybot.TranslationQueue
  alias Walybot.Ecto.{Conversation,Repo,Translation,User}

  @update %{"message" => %{"chat" => %{"all_members_are_administrators" => true, "id" => 1, "title" => "Portuguese to English", "type" => "group"}, "date" => 1502122338, "from" => %{"first_name" => "Michael", "id" => 342536863, "language_code" => "en-US", "username" => "username1"}, "message_id" => 405, "text" => "Que coisa, eh?"}, "update_id" => 375967703}

  test "an end-to-end translation" do
    {:ok, translator} = %{username: "mmmries", telegram_id: 100, is_translator: true}
                        |> User.changeset
                        |> Repo.insert
    {:ok, conversation} = %{telegram_id: 1, name: "woot"} |> Conversation.changeset |> Repo.insert
    Process.register(self(), :"CONVERSATION_1")
    :ok = TranslationQueue.subscribe_to_translations()
    :ok = TranslationQueue.request_translation(@update, conversation)
    assert_receive {:"$gen_call", from, {:please_translate, translation}}
    assert translation.author == "username1"
    assert translation.conversation.telegram_id == 1
    GenServer.reply(from, :ok)
    TranslationQueue.provide_translation(translation, "Who would believe it?", translator)
    assert_receive {:"$gen_call", _from, {:send_translation, "Who would believe it?"}}

    translation = Repo.get!(Translation, translation.id)
    assert translation.translator_id == translator.id
  end

  test "assign new messages to available translators when available" do
    ref = make_ref()
    state = %{
      queue: [],
      translators: [
        %{pid: self(), current_translation: nil, monitor: ref}
      ]
    }
    translation = %Translation{id: 0, author: "example", text: "Que coisa eh?"}

    assert {new_state, translator} = TranslationQueue.assign_to_available_translator(translation, state)
    assert new_state == %{
      queue: [],
      translators: [
        %{pid: self(), current_translation: translation, monitor: ref}
      ]
    }
    assert translator == %{pid: self(), current_translation: translation, monitor: ref}
  end
end
