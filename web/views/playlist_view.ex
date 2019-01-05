defmodule Rumbl.PlaylistView do
  use Rumbl.Web, :view


  def render("playlist.json", %{playlist: play}) do
    %{
      title: play.title,
      url: play.url,
    }
  end
end
