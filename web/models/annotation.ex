defmodule Rumbl.Annotation do
  use Rumbl.Web, :model

  @foreign_key_type :binary_id

  schema "annotations" do
    field :body, :string
    field :at, :integer
    belongs_to :user, Rumbl.User, type: :id
    belongs_to :room, Rumbl.Room, type: :binary_id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:body, :at])
    |> validate_required([:body, :at])
  end
end
