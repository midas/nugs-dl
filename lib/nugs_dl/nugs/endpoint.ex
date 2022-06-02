defmodule NugsDl.Nugs.Endpoint do

  defmacro __using__(_opts) do
    quote do

      @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:67.0) Gecko/20100101 Firefox/67.0"
      @referer "https://play.nugs.net/"
      @orgn "nndesktop"

      @common_headers [
        {"User-Agent", @user_agent},
        {"Referer", @referer},
      ]

      # Private ##########

      defp process_response_body(%{body: body, headers: headers}=response) do
        body =
          body
          |> Jason.decode!()
          #|> Map.take(@expected_fields)
          #|> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)

        Map.merge(response, %{
          body: body,
          cookies: get_cookies(headers),
        })
      end

      defp get_cookies(headers) do
        Enum.map(headers, fn({k,v}) ->
          cond do
            String.match?(k, ~r/\Aset-cookie\z/i) -> v
            true                                  -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.map(fn(cookie) ->
             String.split(cookie, "; ")
             |> List.first()
           end)
      end

    end
  end
end
