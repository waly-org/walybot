defmodule Walybot.Ecto.Repo.Migrations.AddUsersTable do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;"
    create table(:users) do
      add :username, :citext
      add :telegram_id, :integer
      add :is_admin, :boolean
      add :is_translator, :boolean
      timestamps()
    end
  end
end
