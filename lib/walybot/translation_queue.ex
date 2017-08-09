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

  def subscribe_to_translations,do: GenServer.call(__MODULE__, {:subscribe_to_translations, self()})

  ## GenServer Callbacks
  def init(nil) do
    {:ok, %{queue: [], translators: []}}
  end

  def handle_call({:request_translation, translation}, _from, state) do
    new_state = queue_translation(translation, state)
    send self(), :try_to_assign_translations
    {:reply, :ok, new_state}
  end
  def handle_call({:subscribe_to_translations, pid}, _from, state) do
    translator = %{pid: pid, monitor: Process.monitor(pid), current_translation: nil}
    translators = [translator | state.translators]
    send self(), :try_to_assign_translations
    {:reply, :ok, Map.put(state, :translators, translators)}
  end

  def handle_info(:try_to_assign_translations, %{queue: [t|rest]}=state) do
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
end
