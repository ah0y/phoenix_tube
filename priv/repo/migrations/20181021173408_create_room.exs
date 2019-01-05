defmodule Rumbl.Repo.Migrations.CreateRoom do
  use Ecto.Migration

  def change do
    create table(:rooms, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :public, :boolean, default: :false
      add :url, :string
      add :title, :string
      add :user_id, references(:users, on_delete: :delete_all)


      timestamps()
    end
    create index(:rooms, [:user_id])

  end
end
