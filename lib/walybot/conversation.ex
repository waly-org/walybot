defmodule Walybot.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field :name, :string
    field :needs_translation, :boolean, default: false
    field :telegram_id, :integer
    timestamps()
  end

  def changeset(params, translator \\ %Walybot.Translator{}) do
    translator
    |> cast(params, [:username, :is_authorized, :telegram_id])
    |> update_change(:username, &String.downcase/1)
    |> validate_required([:username, :is_authorized])
    |> unique_constraint(:username)
    |> unique_constraint(:telegram_id)
  end
end
