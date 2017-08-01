defmodule Walybot.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field :name, :string
    field :needs_translation, :boolean, default: false
    field :telegram_id, :integer
    timestamps()
  end

  def changeset(params, conversation \\ %Walybot.Conversation{}) do
    conversation
    |> cast(params, [:name, :needs_translation, :telegram_id])
    |> validate_required([:name, :needs_translation, :telegram_id])
    |> unique_constraint(:telegram_id)
  end
end
