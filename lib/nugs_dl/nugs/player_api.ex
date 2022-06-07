defmodule NugsDl.Nugs.PlayerApi do

  use NugsDl.Nugs.Endpoint

  alias NugsDl.Track

  @url "http://streamapi.nugs.net/bigriver/subplayer.aspx"

  def get_track_url(cookies, track_id, format_id) do
    params = [
		  HLS: "1",
		  platformID: format_id,
		  trackID: track_id,
      orgn: @orgn,
    ]

    url = add_query_params(@url, params)
    headers = add_cookies(@common_headers, cookies)

    HTTPoison.get!(url, headers)
    |> process_response()#~w(artistName venue performanceDate tracks))
    #|> IO.inspect()
  end

  def download_track(%Track{stream_url: url}=track, file_path, cookies) do
    headers = add_cookies(@common_headers, cookies)
              |> List.insert_at(0, {"Range", "bytes=0-"})

    async_download = fn(resp, fd, download_fn, filename, total, completed) ->
      resp_id = resp.id

      receive do
        %HTTPoison.AsyncStatus{code: status_code, id: ^resp_id} ->
          HTTPoison.stream_next(resp)
          download_fn.(resp, fd, download_fn, filename, total, completed)

        %HTTPoison.AsyncHeaders{headers: headers, id: ^resp_id} ->
          {_, content_length} =
            headers
            |> Enum.filter(fn({k,_}) -> String.downcase(k) == "content-length" end)
            |> List.first
          {content_length, _} = Integer.parse(content_length)
          HTTPoison.stream_next(resp)
          download_fn.(resp, fd, download_fn, filename, content_length, completed)

        %HTTPoison.AsyncChunk{chunk: chunk, id: ^resp_id} ->
          ProgressBar.render(completed, total)
          IO.binwrite(fd, chunk)
          {:ok, %{size: size}} = File.stat(filename)
          HTTPoison.stream_next(resp)
          download_fn.(resp, fd, download_fn, filename, total, size)

        %HTTPoison.AsyncEnd{id: ^resp_id} ->
          ProgressBar.render(completed, total)
          File.close(fd)
      end
    end

    resp = HTTPoison.get!(url, headers, stream_to: self(), async: :once)

    {:ok, fd} = File.open(file_path, [:write, :binary])

    async_download.(resp, fd, async_download, file_path, 0, 0)
  end

end
