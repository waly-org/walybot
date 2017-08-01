defmodule Walybot.Conversations do
  require Logger

  def queue_for_translation(update) do
    conversation_id = get_in(update, ["message","chat","id"])
    Logger.info "do I need to translate stuff for #{conversation_id}?"
    :ok
  end
end
