defmodule Walybot.Repo.Migrations.AddConversationsTable do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :name, :string
      add :needs_translation, :boolean
      add :telegram_id, :integer

      timestamps()
    end

    create unique_index(:conversations, [:telegram_id])
  end
end
