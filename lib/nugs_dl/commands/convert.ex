defmodule NugsDl.Commands.Convert do

  use NugsDl.Command

  alias NugsDl.Album

  def execute(%{options: opts}=options) do
    IO.puts "Executing the `convert` command with options:"
    blank_line()
    print_options_table(options)

    case File.ls(opts[:in_path]) do
      {:ok, files} ->
        ensure_output_path(opts[:output_path])
        convert_files(files, opts)
      {:error, :enoent} ->
        error("Input path does not exist")
    end
  end

  defp convert_files(files, %{bit_rate: bit_rate, format: format, in_path: in_path, output_path: output_path}=opts) when is_list(files) do
    Enum.each(files, fn(filename) ->
      announce("Converting #{filename} to #{format}")
      in_file = Path.join(in_path, filename)
      out_filename = String.replace(filename, Path.extname(filename), ".#{format}")
      out_file = Path.join(output_path, out_filename)

      System.cmd("ffmpeg", ["-i", in_file, "-acodec", "libmp3lame", "-ab", bit_rate, out_file])
      |> case do
           {stdout, 0} -> success("Done")
           any         -> error("Error: #{inspect(any)}")
         end
    end)
  end

  defp ensure_output_path(path) do
    File.mkdir_p(path)
  end

end
