defmodule NugsDl.Command do

  defmacro __using__(_opts) do
    quote location: :keep do

      use Tabula, style: :github_md

      defp announce(msg),
        do: IO.puts("\e[0;36m==> #{msg}\e[0;0m")

      defp blank_line,
        do: IO.puts("")

      defp success(msg),
        do: IO.puts("\e[0;32m#{msg}\e[0;0m")

      defp error(msg),
        do: IO.puts("\e[0;31m#{msg}\e[0;0m")

      defp print_options_table(options) do
        all_options =
          options.options
          |> Map.merge(options.args)
          |> Map.merge(options.flags)

        Enum.map(all_options, fn({k,v}) ->
          k =
            Atom.to_string(k)
            |> String.replace("_", "-")

          %{"Option" => k, "Value" => v}
        end)
        |> Tabula.print_table
      end

    end
  end

end
