defmodule NugsDl.Commands.Download do

  use NugsDl.Command

  alias NugsDl.Nugs.{Api, PlayerApi, SecureApi}
  alias NugsDl.Album

  def execute(%{options: %{album_ids: album_ids, convert: convert, ext: ext, file_type: file_type, format_id: format_id, user: user, password: password, output_path: output_path}=opts}=options) do
    IO.puts "Executing the `download` command with options:"
    blank_line()
    print_options_table(options)

    blank_line()
    announce("Authenticating and fetching subscriber info")
    {:ok, %{cookies: auth_cookies}} = SecureApi.authenticate(user, password)

    {:ok, %{body: sub_body, cookies: sub_cookies}} = SecureApi.get_subscriber_info(auth_cookies)

    cookies = auth_cookies ++ sub_cookies
    plan_name = sub_body["Response"]["subscriptionInfo"]["planName"]

    success("Signed in successfully | " <> plan_name <> " account.")

    albums_count = Enum.count(album_ids)

    blank_line()
    announce("Fetching metadata for #{albums_count} album(s)")
    albums =
      album_ids
      |> Stream.with_index
      |> Enum.map(fn({album_id, idx}) ->
           ProgressBar.render(idx, albums_count)
           {:ok, response} = Api.get_album_meta(cookies, album_id)
           results =
             Map.get(response, :body)["Response"]
             |> Album.new()
           ProgressBar.render(idx+1, albums_count)
           results
         end)
    success()

    albums =
      Enum.map(albums, fn(album) ->
        tracks_count = Enum.count(album.tracks)
        blank_line()
        announce("Fetching track URLs for #{tracks_count} tracks from: #{album.artist_name} | #{album.title}")
        tracks =
          album.tracks
          |> Stream.with_index()
          |> Enum.map(fn({track, idx}) ->
            ProgressBar.render(idx, tracks_count)
            {:ok, response} = PlayerApi.get_track_url(cookies, track.id, format_id)
            streamLink = Map.get(response, :body)["streamLink"]
            result = %{track | stream_url: streamLink}
            ProgressBar.render(idx+1, tracks_count)
            result
          end)

        %{album | tracks: tracks}
      end)

    # download tracks
    Enum.each(albums, fn(album) ->
      blank_line()
      announce("Downloading album: #{album.artist_name} | #{album.title}")
      album_path = Path.join([output_path, album.artist_name, album.title, file_type])

      Enum.each(album.tracks, fn(track) ->
        File.mkdir_p(album_path)
        file_path = Path.join([album_path, "#{track.disc_num}-#{track.set_num}-#{track.track_num} - #{track.title}#{ext}"])
        IO.puts("Downloading track: #{track.disc_num}-#{track.set_num}-#{track.track_num} #{track.title}#{ext}")# to #{file_path}")
        PlayerApi.download_track(track, file_path, cookies)
      end)

      unless is_nil(convert) do
        convert_tracks(opts, album_path)
      end
    end)
  end

  defp convert_tracks(options, in_path) do
    blank_line()
    announce("Converting tracks")

    options =
      options[:convert]
      |> Map.merge(%{
           in_path: in_path,
           output_path: Path.join(Path.dirname(in_path), options[:convert][:format])
         })

    NugsDl.Commands.Convert.execute(%{options: options, args: %{}, flags: %{}})
  end

end
