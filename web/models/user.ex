defmodule Rumbl.User do
	use Rumbl.Web, :model

  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    has_many :rooms, Rumbl.Room
    has_many :annotations, Rumbl.Annotation
    has_many :playlists, through: [:rooms, :playlist]

    timestamps
  end
	
	def changeset(model, params \\ %{} ) do
		model
		|> cast(params, ~w(name username password), [])
		|> validate_required([:username, :name, :password])
    |> validate_length(:username, min: 1, max: 20)
    |> validate_length(:password, min: 6, max: 100)
    |> unique_constraint(:username)
	end

	def registration_changeset(model, params \\ %{} ) do
		model
		|> changeset(params)
    |> validate_length(:password, min: 6, max: 100)
    |> cast(params, ~w(password), [])
		|> put_pass_hash()
	end
	
	defp put_pass_hash(changeset) do
		case changeset do
		 %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
		put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
		_->
		 changeset
		end
	end
end


