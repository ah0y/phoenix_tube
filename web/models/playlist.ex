defmodule Rumbl.Playlist do
  use Rumbl.Web, :model

  @foreign_key_type :binary_id

  schema "playlist" do
    field :title, :string
    field :url, :string
    belongs_to :room, Rumbl.Room, type: :binary_id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    HTTPoison.start
    regex = 	~r{^.*(?:youtu\.be\/|\w+\/|v=)(?<id>[^#&?]*)}
    [_, vid] = Regex.run(regex, params["url"])
    json_data = HTTPoison.get! "https://www.googleapis.com/youtube/v3/videos?id=#{vid}&key=#{System.get_env("YOUTUBE_API_KEY")}&part=snippet,statistics,contentDetails&fields=items(id,snippet(title,thumbnails(high)),statistics(viewCount),contentDetails(duration))"
    data = Poison.decode!(json_data.body)
    data_hd = hd(data["items"])
    title = data_hd["snippet"]["title"]
    id = %{title: title}

    struct
    |> cast(params, [:url])
    |> cast(id, [:title])
    |> validate_required([:url])
  end
end
