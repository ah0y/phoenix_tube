defmodule Rumbl.RoomChannel do 
	use Rumbl.Web, :channel
	
	alias Rumbl.AnnotationView
	alias Rumbl.PlaylistView
	alias Rumbl.Room
	alias Rumbl.Presence
	alias Rumbl.User
	alias Rumbl.UserView

	def join("rooms:" <> room_id, params, socket) do
		last_seen_id = params["last_seen_id"] || 0
		room = Repo.get!(Rumbl.Room, room_id)

    annotations = Repo.all(
			from a in assoc(room, :annotations),
				order_by: [asc: a.inserted_at],
				limit: 200, 
				preload: [:user]
		)


    playlist = Repo.all(
			from p in assoc(room, :playlists),
				order_by: [asc: p.inserted_at],
				distinct: p.url,
				limit: 200
		)

    resp = %{annotations: Phoenix.View.render_many(annotations, AnnotationView, "annotation.json"),playlist: Phoenix.View.render_many(playlist, PlaylistView, "playlist.json")}

    send(self(), :after_join)
    {:ok, resp, assign(socket, :room_id, room_id)}
	end

  def handle_info(:after_join, socket) do
#		require IEx; IEx.pry
    Presence.track(socket, socket.assigns.user_id, %{
			username: Repo.all( from u in "users", where: u.id == ^socket.assigns.user_id, select: u.username),
      online_at: inspect(System.system_time(:second))
    })
    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}

  end

	def handle_in("users_count",params, user, socket) do
#		require IEx; IEx.pry
		map_size(Presence.list(socket.topic))
    changeset =
      Repo.get!(Rumbl.Room, socket.assigns.room_id)
      |> Rumbl.Room.update_online(%{online: map_size(Presence.list(socket.topic))})

    Repo.update(changeset)

#    broadcast! socket, "play_video", params
    {:noreply, socket}
	end

  def handle_in(event, params, socket) do
		user = Repo.get(Rumbl.User, socket.assigns.user_id)
		handle_in(event, params, user, socket)
	end

	def handle_in("new_annotation", params, user, socket) do 
		changeset = 
			user
      |> build_assoc(:annotations, room_id: socket.assigns.room_id)
			|> Rumbl.Annotation.changeset(params)
		case Repo.insert(changeset) do 
			{:ok, annotation} ->
				broadcast_annotation(socket, annotation) 
#				Task.start_link(fn -> compute_additional_info(annotation, socket) end)
			
			{:reply, :ok, socket}

			{:error, changeset} ->
				{:reply, {:error, %{errors: changeset}}, socket}
		end
	end

	def handle_in("paused", params, user, socket) do
			broadcast!  socket, "paused", params
			{:noreply, socket}
	end

  def handle_in("playing", params, user, socket) do
    broadcast!  socket, "playing", params
    {:noreply, socket}

  end

	def handle_in("play_video", params, user, socket) do
    changeset =
      Repo.get!(Rumbl.Room, socket.assigns.room_id)
			|> Rumbl.Room.update_url(params)

		Repo.update(changeset)

		broadcast! socket, "play_video", params
    {:noreply, socket}


  end

	def handle_in("new_video", params, user, socket) do
    changeset =
      Repo.get!(Rumbl.Room, socket.assigns.room_id)
      |> build_assoc(:playlists, room_id: socket.assigns.room_id)
      |> Rumbl.Playlist.changeset(params)

    case Repo.insert(changeset) do
      {:ok, playlist} ->
        broadcast_playlist(socket, playlist)

        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end

	end

	defp broadcast_playlist(socket, playlist) do
		playlist = Repo.preload(playlist, :room)
		rendered_playlist = Phoenix.View.render(PlaylistView, "playlist.json", %{
			playlist: playlist
		})

		broadcast! socket, "new_video", rendered_playlist

	end

	defp broadcast_annotation(socket, annotation) do 
		annotation = Repo.preload(annotation, :user)
		rendered_ann = Phoenix.View.render(AnnotationView, "annotation.json", %{
			annotation: annotation
		})
		broadcast! socket, "new_annotation", rendered_ann
	end

  def terminate(reason, socket) do
		IO.inspect reason
		IO.puts map_size(Presence.list(socket.topic))

    map_size(Presence.list(socket.topic))
    changeset =
      Repo.get!(Rumbl.Room, socket.assigns.room_id)
      |> Rumbl.Room.update_online(%{online: map_size(Presence.list(socket.topic))-1})

    Repo.update(changeset)

    :ok
  end
	
	defp compute_additional_info(ann, socket) do 
		for result <- Rumbl.InfoSys.compute(ann.body, limit: 1, timeout: 10_000) do
			attrs = %{url: result.url, body: result.text, at: ann.at}
			info_changeset =
				Repo.get_by!(Rumbl.User, username: result.backend)
				|> build_assoc(:annotations, room_id: ann.room_id)
				|> Rumbl.Annotation.changeset(attrs)

			case Repo.insert(info_changeset) do 
				{:ok, info_ann} -> broadcast_annotation(socket, info_ann)
				{:error, _changeset} -> :ignore
			end
		end
	end
end


