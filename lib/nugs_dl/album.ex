defmodule NugsDl.Album do

  alias NugsDl.Track

  defstruct ~w(
    artist_name
    performance_date
    tracks
    title
    venue
  )a

  def new(%{
      "artistName" => artist_name,
      "venue" => venue,
      "performanceDate" => performance_date,
      "tracks" => tracks,
    })
  do
    performance_date = convert_to_date(String.trim(performance_date))

    %__MODULE__{
      artist_name: String.trim(artist_name),
      performance_date: performance_date,
      title: "#{Date.to_iso8601(performance_date)} - #{venue}",
      tracks: Enum.map(tracks, &Track.new/1),
      venue: String.trim(venue),
    }
  end

  defp convert_to_date(str) do
    [m,d,y] =
      str
      |> String.split("/")
      |> Enum.map(fn(e) -> {i,_} = Integer.parse(e) ; i end)

    {:ok, date} = Date.from_erl({y,m,d})
    date
  end

end
