defmodule Rumbl.Repo.Migrations.CreateAnnotation do
  use Ecto.Migration

  def change do
    create table(:annotations) do
      add :body, :text
      add :at, :integer
      add :user_id, references(:users, on_delete: :delete_all)
      add :room_id, references(:rooms, on_delete: :delete_all, type: :uuid)

      timestamps()
    end
    create index(:annotations, [:user_id])
    create index(:annotations, [:room_id])

  end
end
