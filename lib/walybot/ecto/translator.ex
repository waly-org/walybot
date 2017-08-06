defmodule Walybot.Ecto.Translator do
  use Ecto.Schema
  import Ecto.Changeset

  schema "translators" do
    field :username, :string
    field :is_authorized, :boolean, default: false
    field :telegram_id, :integer
    timestamps()
  end

  def changeset(params, translator \\ %__MODULE__{}) do
    translator
    |> cast(params, [:username, :is_authorized, :telegram_id])
    |> update_change(:username, &String.downcase/1)
    |> validate_required([:username, :is_authorized])
    |> unique_constraint(:username)
    |> unique_constraint(:telegram_id)
  end
end
