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
    |> process_response()
  end

  def get_subscriber_info(cookies) do
    params = [
      orgn: @orgn,
      method: "user.site.getSubscriberInfo"
    ]

    url = add_query_params(@url, params)
    headers = add_cookies(@common_headers, cookies)

    HTTPoison.get!(url, headers)
    |> process_response()
  end

end
