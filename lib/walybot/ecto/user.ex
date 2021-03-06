defmodule Walybot.Ecto.User do
  use Ecto.Schema
  import Ecto.{Changeset,Query}
  alias Walybot.Ecto.Repo

  schema "users" do
    field :username, :string
    field :telegram_id, :integer
    field :is_admin, :boolean, default: false
    field :is_translator, :boolean, default: false
    timestamps()
  end

  def changeset(params, translator \\ %__MODULE__{}) do
    translator
    |> cast(params, [:username, :telegram_id, :is_admin, :is_translator])
    |> validate_required([:username])
    |> unique_constraint(:username)
    |> unique_constraint(:telegram_id)
  end

  def first_or_create(username) do
    case __MODULE__ |> where(username: ^username) |> Repo.one do
      nil -> %{username: username} |> changeset |> Repo.insert
      user -> {:ok, user}
    end
  end

  def first_or_create(telegram_id, username) do
    case __MODULE__ |> where(telegram_id: ^telegram_id) |> or_where(username: ^username) |> Repo.one do
      nil -> %{telegram_id: telegram_id, username: username} |> changeset |> Repo.insert
      user -> {:ok, user}
    end
  end
end
