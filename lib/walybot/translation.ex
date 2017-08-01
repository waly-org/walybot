defmodule Walybot.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "translations" do
    field :author, :string
    field :text, :string
    field :translation, :string

    belongs_to :conversation, Walybot.Conversation
    belongs_to :translator, Walybot.Translator
    timestamps()
  end

  def create_changeset(params, conversation) do
    %__MODULE__{}
    |> cast(params, [:author, :text])
    |> put_assoc(:conversation, conversation)
    |> assoc_constraint(:conversation)
    |> validate_required([:author, :text])
  end
end
