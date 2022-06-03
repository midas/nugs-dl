defmodule NugsDl.Album do

  alias NugsDl.Track

  defstruct ~w(
    artist_name
    city
    extracted_locations?
    performance_date
    state
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

    case extract_state_and_city(venue) do
      {:extracted, venue, city, state} ->
        %__MODULE__{
          artist_name: String.trim(artist_name),
          city: city,
          extracted_locations?: true,
          performance_date: performance_date,
          state: state,
          title: "#{Date.to_iso8601(performance_date)} - #{city}, #{state} - #{venue}",
          tracks: Enum.map(tracks, &Track.new/1),
          venue: String.trim(venue),
        }
      {:no_extraction, venue}->
        %__MODULE__{
          artist_name: String.trim(artist_name),
          extracted_locations?: true,
          performance_date: performance_date,
          title: "#{Date.to_iso8601(performance_date)} - #{venue}",
          tracks: Enum.map(tracks, &Track.new/1),
          venue: String.trim(venue),
        }
    end
  end

  defp convert_to_date(str) do
    [m,d,y] =
      str
      |> String.split("/")
      |> Enum.map(fn(e) -> {i,_} = Integer.parse(e) ; i end)

    {:ok, date} = Date.from_erl({y,m,d})
    date
  end

  defp extract_state_and_city(venue) do
    String.split(venue, ", ")
    |> handle_extract_state_and_city()
  end

  defp handle_extract_state_and_city([venue, state, city]) do
    {:extracted, String.trim(venue), String.trim(city), String.trim(state)}
  end

  defp handle_extract_state_and_city(venue) when is_binary(venue) do
    {:no_extraction, venue}
  end

end
