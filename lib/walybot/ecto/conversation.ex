defmodule Walybot.Ecto.Conversation do
  use Ecto.Schema
  import Ecto.{Changeset,Query}
  alias Walybot.Ecto.Repo

  schema "conversations" do
    field :name, :string
    field :needs_translation, :boolean, default: false
    field :telegram_id, :integer
    timestamps()
  end

  def changeset(params, conversation \\ %__MODULE__{}) do
    conversation
    |> cast(params, [:name, :needs_translation, :telegram_id])
    |> validate_required([:needs_translation, :telegram_id])
    |> unique_constraint(:telegram_id)
  end

  def first_or_create(telegram_id) do
    case __MODULE__ |> where(telegram_id: ^telegram_id) |> Repo.one do
      nil -> %{telegram_id: telegram_id} |> changeset |> Repo.insert
      conversation -> {:ok, conversation}
    end
  end
end
