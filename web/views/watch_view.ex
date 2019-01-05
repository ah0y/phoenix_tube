defmodule Rumbl.WatchView do 
	use Rumbl.Web, :view
	
	def player_id(room) do
		~r{^.*(?:youtu\.be\/|\w+\/|v=)(?<id>[^#&?]*)}
		|> Regex.named_captures(room.url)
		|> get_in(["id"])
	end
end



