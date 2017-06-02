defmodule Walybot.Translator do
  use Ecto.Schema

  schema "translators" do
    field :username, :string
    field :is_authorized, :boolean, default: false
    field :telegram_id, :integer
    timestamps()
  end
end
