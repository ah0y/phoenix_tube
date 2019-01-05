defmodule Rumbl.WatchController do 
	use Rumbl.Web, :controller
  plug :authenticate_user when action in [:show]
  alias Rumbl.Room

  def show(conn, %{"id" => id}) do
		room = Repo.get!(Room, id)
		render conn, "show.html", room: room
	end
end


