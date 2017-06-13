defmodule Walybot.Repo.Migrations.AddUniqueUsernameIndex do
  use Ecto.Migration

  def change do
    create unique_index(:translators, [:username])
  end
end
