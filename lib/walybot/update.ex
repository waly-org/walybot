defmodule Walybot.Update do
  def conversation_id(update) do
    get_in(update, ["message", "chat", "id"])
    || get_in(update, ["callback_query","message", "chat", "id"])
  end

  def conversation_name(update) do
    get_in(update, ["message","chat","title"])
    || get_in(update, ["message","chat","username"])
    || get_in(update, ["callback_query", "message","chat","title"])
    || get_in(update, ["callback_query","message","chat","username"])
  end

  def sender_id(update) do
    get_in(update, ["message","from","id"])
    || get_in(update, ["callback_query","message","from","id"])
  end

  def sender_name(update) do
    get_in(update, ["message","from","username"])
    || get_in(update, ["callback_query","message","from","username"])
  end
end
