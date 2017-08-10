defmodule Walybot.TranslationQueue do
  use GenServer
  alias Walybot.Ecto.{Repo,Translation}
  require Logger

  def request_translation(%{"message" => %{"from" => %{"username" => username}, "text" => text}}, conversation) do
    params = %{author: username, text: text}
    with {:ok, translation} <- params |> Translation.create_changeset(conversation) |> Repo.insert,
         translation <- Map.put(translation, :conversation, conversation),
    do: GenServer.call(__MODULE__, {:request_translation, translation})
  end

  def start_link, do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def provide_translation(translation, translated_text, user) do
    GenServer.call(__MODULE__, {:provide_translation, translation, translated_text, user})
  end

  def subscribe_to_translations, do: GenServer.call(__MODULE__, {:subscribe_to_translations, self()})

  def unsubscribe_from_translations, do: GenServer.call(__MODULE__, {:unsubscribe_from_translations, self()})

  ## GenServer Callbacks
  def init(nil) do
    {:ok, %{queue: [], translators: []}}
  end

  def handle_call({:provide_translation, translation, translated_text, user}, _from, state) do
    # TODO sanity check that this translation matches one that is currently assigned
    new_state = unassign_pending_translation(translation, state)
    {:ok, translation} = translation |> Translation.update_changeset(user, translated_text) |> Repo.update
    send self(), {:deliver_translation, translation}
    {:reply, :ok, new_state}
  end
  def handle_call({:request_translation, translation}, _from, state) do
    new_state = queue_translation(translation, state)
    send self(), :try_to_assign_translations
    {:reply, :ok, new_state}
  end
  def handle_call({:subscribe_to_translations, pid}, _from, state) do
    Logger.info "#{__MODULE__} getting subscription from #{inspect pid}"
    translator = %{pid: pid, monitor: Process.monitor(pid), current_translation: nil}
    translators = [translator | state.translators]
    send self(), :try_to_assign_translations
    {:reply, :ok, Map.put(state, :translators, translators)}
  end
  def handle_call({:unsubscribe_from_translations, pid}, _from, state) do
    Logger.info "#{__MODULE__} translator #{inspect pid} unsubscribed from translations"
    {:reply, :ok, remove_translator(pid, state)}
  end
  def handle_info({:DOWN, ref, :process, _, _}, state) do
    {:noreply, remove_translator(ref, state)}
  end
  def handle_info({:deliver_translation, translation}, state) do
    :ok = Walybot.Conversations.send_translation(translation)
    {:noreply, state}
  end
  def handle_info(:try_to_assign_translations, %{queue: [t|rest]}=state) do
    Logger.info "#{__MODULE__} :try_to_assign_translations #{inspect t}"
    case assign_to_available_translator(t, state) do
      {new_state, %{pid: translator_pid}} ->
        new_state = Map.put(state, :queue, rest)
        :ok = GenServer.call(translator_pid, {:please_translate, t})
        {:noreply, new_state}
      false ->
        {:noreply, state}
    end
  end
  def handle_info(:try_to_assign_translations, state), do: {:noreply, state}
  def handle_info(other, state) do
    Logger.error("#{__MODULE__} received unpexpected message #{inspect other}")
    {:noreply, state}
  end

  ## Implmentation
  def assign_to_available_translator(translation, %{translators: translators}=state) do
    case Enum.find(translators, &( &1.current_translation == nil )) do
      nil -> false
      translator ->
        translator = Map.put(translator, :current_translation, translation)
        translators = [translator | translators] |> Enum.uniq_by(&( &1.pid ))
        new_state = Map.put(state, :translators, translators)
        {new_state, translator}
    end
  end

  def queue_translation(translation, %{queue: q}=state) do
    q = q ++ [translation]
    Map.put(state, :queue, q)
  end

  def remove_translator(ref_or_pid, %{translators: translators}=state) do
    # TODO re-queue the current translation if it has one?
    translators = Enum.reject(state.translators, &( &1.monitor == ref_or_pid || &1.pid == ref_or_pid ))
    Map.put(state, :translators, translators)
  end

  def unassign_pending_translation(%{id: translation_id}, %{translators: translators}=state) do
    new_translators = Enum.map(translators, fn(translator) ->
      case translator.current_translation do
        %{id: translation_id} -> Map.put(translator, :current_translation, nil)
        _ -> translator
      end
    end)
    Map.put(state, :translators, translators)
  end
end
