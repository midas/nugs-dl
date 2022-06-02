defmodule NugsDl.Nugs.SecureApi do

  use NugsDl.Nugs.Endpoint

  @url "http://streamapi.nugs.net/secureapi.aspx"

  def authenticate(email, password) do
    params = [
      username: email,
      pw: password,
      orgn: @orgn,
      method: "user.site.login"
    ]

    query = URI.encode_query(params)
    url = @url <> "?" <> query

    HTTPoison.get!(url, @common_headers)
    |> process_response_body()
    |> IO.inspect()
  end


end
