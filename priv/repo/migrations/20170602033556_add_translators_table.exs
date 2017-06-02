defmodule Walybot.Repo.Migrations.AddTranslatorsTable do
  use Ecto.Migration

  def change do
    create table(:translators) do
      add :username, :text
      add :is_authorized, :boolean
      add :telegram_id, :integer

      timestamps()
    end

    create unique_index(:translators, [:telegram_id])
  end
end
