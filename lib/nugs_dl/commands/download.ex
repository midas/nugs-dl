defmodule NugsDl.Commands.Download do

  def execute(%{options: %{user: user, password: password}}=options) do
    IO.inspect(options, label: "DOWNLOAD CMD OPTIONS")
    NugsDl.Nugs.SecureApi.authenticate(user, password)
  end

end
