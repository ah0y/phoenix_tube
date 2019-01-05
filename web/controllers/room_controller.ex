defmodule Rumbl.RoomController do
  use Rumbl.Web, :controller
  use Rummage.Phoenix.Controller
  plug :authenticate_user when action in [:new]
  alias Rumbl.Room

  def index(conn, params, user) do
#    require IEx; IEx.pry()

    {query, rummage} = Room
     |> Room.rummage(params["rummage"])

    public = from r in query, where: [public: true]

    rooms = Repo.all(public)

    rooms = Enum.shuffle(rooms)
    render(conn, "index.html", rooms: rooms, rummage: rummage)
  end

  def new(conn, _params, user) do
  	changeset =
		user	
		|> build_assoc(:rooms)
		|> Room.changeset()
	render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"room" => room_params}, user) do

    changeset =
      user
      |> build_assoc(:rooms)
      |> Room.changeset(room_params)


    case Repo.insert(changeset) do
      {:ok, _room} ->
        conn
        |> put_flash(:info, "Room created successfully.")
        |> redirect(to: watch_path(conn, :show, Map.get(_room, :id)))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, user) do
    room = Repo.get!(user_rooms(user), id)
    render(conn, "show.html", room: room)
  end

  def edit(conn, %{"id" => id}, user) do
    room = Repo.get!(user_rooms(user), id)
    changeset = Room.changeset(room)
    render(conn, "edit.html", room: room, changeset: changeset)
  end

  def update(conn, %{"id" => id, "room" => room_params}, user) do
    room = Repo.get!(user_rooms(user), id)
    changeset = Room.changeset(room, room_params)

    case Repo.update(changeset) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "Room updated successfully.")
        |> redirect(to: room_path(conn, :show, room))
      {:error, changeset} ->
        render(conn, "edit.html", room: room, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, user) do
    room = Repo.get!(user_rooms(user), id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(room)

    conn
    |> put_flash(:info, "Room deleted successfully.")
    |> redirect(to: room_path(conn, :index))
  end

  def action(conn, _) do 
	apply(__MODULE__, action_name(conn),
		[conn, conn.params, conn.assigns.current_user])
  end
  
  defp user_rooms(user) do 
	  assoc(user, :rooms)
  end


end
