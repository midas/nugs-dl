defmodule NugsDl.Command do

  defmacro __using__(_opts) do
    quote location: :keep do

      defp blank_line,
        do: IO.puts("")

      defp success(msg),
        do: IO.puts("\e[0;32m#{msg}\e[0;0m")

      defp error(msg),
        do: IO.puts("\e[0;31m#{msg}\e[0;0m")

    end
  end

end
