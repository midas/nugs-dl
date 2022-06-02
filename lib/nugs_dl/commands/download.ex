defmodule NugsDl.Commands.Download do

  use NugsDl.Command

  alias NugsDl.Nugs.{Api, SecureApi}
  alias NugsDl.Album

  def execute(%{options: %{album_ids: album_ids, user: user, password: password}}=options) do
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

    blank_line()
    announce("Fetching metadata for #{Enum.count(album_ids)} album(s)")
    {:ok, responses} = Api.get_album_metas(cookies, album_ids)
    album_metadatas = Enum.map(responses, fn(response) -> Map.get(response, :body)["Response"] end)
    albums = Enum.map(album_metadatas, &Album.new/1)
           #|> IO.inspect()
    success("Done")
  end

end
