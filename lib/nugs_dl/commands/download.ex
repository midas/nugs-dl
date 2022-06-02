defmodule NugsDl.Commands.Download do

  use NugsDl.Command

  def execute(%{options: %{user: user, password: password}}=options) do
    {:ok, %{cookies: auth_cookies}} =
      NugsDl.Nugs.SecureApi.authenticate(user, password)

    {:ok, %{body: sub_body, cookies: sub_cookies}} =
      NugsDl.Nugs.SecureApi.get_subscriber_info(auth_cookies)

    cookies = auth_cookies ++ sub_cookies
    plan_name = sub_body["Response"]["subscriptionInfo"]["planName"]

    success("Signed in successfully | " <> plan_name <> " account.")

    blank_line()
    IO.inspect(options, label: "DOWNLOAD CMD OPTIONS")
  end

end
