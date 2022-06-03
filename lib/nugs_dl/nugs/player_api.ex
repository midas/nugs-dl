defmodule NugsDl.Nugs.PlayerApi do

  use NugsDl.Nugs.Endpoint

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

end
