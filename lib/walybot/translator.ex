defmodule Walybot.Translator do
  use Ecto.Schema
  import Ecto.Changeset

  schema "translators" do
    field :username, :string
    field :is_authorized, :boolean, default: false
    field :telegram_id, :integer
    timestamps()
  end

  def changeset(params, translator \\ %Walybot.Translator{}) do
    translator
    |> cast(params, [:username, :is_authorized, :telegram_id])
    |> validate_required([:username, :is_authorized])
  end
end
