defmodule Walybot.Ecto.Repo.Migrations.MakeUsernamesAndIdsUnique do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:username])
    create unique_index(:users, [:telegram_id])
  end
end
