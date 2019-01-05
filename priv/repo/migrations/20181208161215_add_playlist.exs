defmodule Rumbl.Repo.Migrations.AddPlaylist do
  use Ecto.Migration

  def change do

    create table(:playlist) do

      add :room_id, references(:rooms, on_delete: :delete_all, type: :uuid)

      add :title, :string

      add :url, :string

      timestamps()

    end

    create index(:playlist, [:room_id])


  end



end
