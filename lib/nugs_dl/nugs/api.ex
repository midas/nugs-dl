defmodule NugsDl.Nugs.Api do

  use NugsDl.Nugs.Endpoint

  @url "http://streamapi.nugs.net/api.aspx"

  def get_album_meta(cookies, album_id) do
    params = [
		  containerID: album_id,
      orgn: @orgn,
      method: "catalog.container"
    ]

    url = add_query_params(@url, params)
    headers = add_cookies(@common_headers, cookies)

    HTTPoison.get!(url, headers)
    |> process_response(~w(artistName venue performanceDate tracks))
    #|> IO.inspect(label: "RESPONSES")
  end

end
