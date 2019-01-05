defmodule Rumbl.Room do
  use Rumbl.Web, :model
  use Rummage.Ecto

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  schema "rooms" do
    field :url, :string
    field :title, :string
    field :public, :boolean, default: false
    field :online, :integer
    belongs_to :user, Rumbl.User
    has_many :annotations, Rumbl.Annotation
    has_many :playlists, Rumbl.Playlist

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  @update_url ~w(url)
  def update_url(model, params \\ %{}) do
    model
    |> cast(params, @update_url)
  end

  @update_online ~w(online)
  def update_online(model, params \\ %{}) do
    model
    |> cast(params, @update_online)
  end

  @required_fields ~w(url title public)
  def changeset(model, params \\ %{} )do
    model
    |> cast(params, @required_fields)
    |> validate_required([:url, :title])
  end
end
