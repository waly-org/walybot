defmodule Walybot.Repo.Migrations.AddTranslations do
  use Ecto.Migration

  def change do
    create table(:translations) do
      add :author, :string
      add :conversation_id, references(:conversations)
      add :text, :text
      add :translation, :text
      add :translator_id, references(:translators)

      timestamps()
    end
  end
end
