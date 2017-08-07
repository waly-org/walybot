defmodule Walybot.Ecto.Repo.Migrations.MoveTranslationsToPointAtUsersTable do
  use Ecto.Migration

  def change do
    drop table(:translations)
    drop table(:translators)

    create table(:translations) do
      add :author, :string
      add :conversation_id, references(:conversations)
      add :text, :text
      add :translation, :text
      add :translator_id, references(:users)
      timestamps()
    end
  end
end
