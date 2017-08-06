defmodule Walybot.Ecto.Translation do
  use Ecto.Schema
  import Ecto.{Changeset,Query}
  alias Walybot.Ecto.Repo

  schema "translations" do
    field :author, :string
    field :text, :string
    field :translation, :string

    belongs_to :conversation, Walybot.Ecto.Conversation
    belongs_to :translator, Walybot.Ecto.Translator
    timestamps()
  end

  def create_changeset(params, conversation) do
    %__MODULE__{}
    |> cast(params, [:author, :text])
    |> put_assoc(:conversation, conversation)
    |> assoc_constraint(:conversation)
    |> validate_required([:author, :text])
  end

  def update_changeset(translation, translator, translated_text) do
    translation
    |> cast(%{translation: translated_text, translator_id: translator.id}, [:translation, :translator_id])
    |> assoc_constraint(:translator)
    |> validate_required([:translation])
  end

  def one_pending_translation do
    result = __MODULE__ |> where([t], is_nil(t.translation)) |> limit(1) |> Repo.one
    case result do
      nil -> {:error, "no pending translations"}
      translation -> {:ok, translation}
    end
  end

  @doc """
  Returns the last messages in the conversation leading up to the translation message passed

  The messages are returned in chronological order as a list with size 0..2
  """
  def recent_translations(%{conversation_id: conversation_id, inserted_at: inserted_at}) do
    __MODULE__
    |> where(conversation_id: ^conversation_id)
    |> where([t], t.inserted_at < ^inserted_at)
    |> order_by(desc: :inserted_at)
    |> limit(2)
    |> Repo.all
    |> Enum.reverse
  end
end
