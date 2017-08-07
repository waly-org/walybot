defmodule Walybot.Ecto.Repo.Migrations.AddUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :text
      add :telegram_id, :integer
      add :is_admin, :boolean
      add :is_translator, :boolean
      timestamps()
    end
  end
end
