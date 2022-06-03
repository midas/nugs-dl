defmodule NugsDl.CLI do

  use Bakeware.Script

  #def start(_, _) do
    ## Returning `{:ok, pid}` will prevent the application from halting.
    ## Use System.halt(exit_code) to terminate the VM when required
    #Burrito.Util.Args.get_arguments()
    #|> execute()

    #System.halt(0)
  #end

  @impl Bakeware.Script
  def main(argv) do
    #IO.puts "=====> EScript Entypoint"
    print_title()
    execute(argv)
    0
  end

  defp execute(argv) do
    {:ok, vsn} = :application.get_key(:nugs_dl, :vsn)

    Optimus.new!(
      name: "nugs-dl",
      description: "A downloader for Nugs.net albums",
      version: Kernel.to_string(vsn),
      #author: "Jason Harrelson",
      #about: "Utility for calculating statistic metrics of values read from a file for a certain period of time",
      allow_unknown_args: true,
      parse_double_dash: true,
      subcommands: [
        download: [
          name: "download",
          about: "Downloads one or more albums",
          options: [
            user: [
              value_name: "USER",
              short: "-u",
              long: "--user",
              help: "The user to use when authenticating with Nugs.net (usually an email address)",
              required: true
            ],
            output_path: [
              value_name: "OUTPUT_PATH",
              short: "-o",
              long: "--output-path",
              help: "The folder to write the downloaded files to",
              required: true
            ],
            password: [
              value_name: "PASSWORD",
              short: "-p",
              long: "--password",
              help: "The password to use when authenticating with Nugs.net",
              required: true
            ],
            album_ids: [
              value_name: "ALBUM_IDS",
              short: "-a",
              long: "--album-ids",
              help: "A comma delimited list of album IDs to download",
              required: true,
              parser: fn(s) ->
                {:ok, String.split(s, ",")}
              end,
            ],
            quality: [
              value_name: "QUALITY",
              short: "-q",
              long: "--quality",
              help: "The quality of tracks to download (1: FLAC, 2: ALAC, 4: M4A)",
              required: true
            ],
          ],
        ]
      ]
    )
    |> Optimus.parse!(argv)
    |> process_command()
  end

  defp process_command({[:download], options}) do
    options
    |> populate_calculated_args()
    |> NugsDl.Commands.Download.execute()
  end

  defp process_command(options) do
    IO.inspect(options, label: "--- process_command CATCH ALL ---")
  end

  defp populate_calculated_args(options) do
    opts = options.options

    opts =
      case opts[:quality] do
        "1" ->
          Map.merge(opts, %{
            quality: "16-bit / 44.1kHz FLAC",
            format_id: 1
          })
        "2" ->
          Map.merge(opts, %{
            quality: "16-bit / 44.1kHz ALAC",
            format_id: 2
          })
        "4" ->
          Map.merge(opts, %{
            quality: "24-bit MQA",
            format_id: 4
          })
        _ ->
          Map.merge(opts, %{
            quality: "AAC 150",
            format_id: nil # TODO ????
          })
      end

      opts =
        case opts[:format_id] do
          1 ->
            Map.merge(opts, %{
              ext: ".flac",
              file_type: "flac",
            })
          2 ->
            Map.merge(opts, %{
              ext: ".alac.m4a",
              file_type: "alac",
            })
          _ ->
            Map.merge(opts, %{
              ext: ".m4a",
              file_type: "m4a",
            })
        end

    Map.put(options, :options, opts)
  end

  defp print_title do
    IO.puts("""

       _____                 ____  __
      |   | |_ _ ___ ___ ___|    \\|  |
      | | | | | | . |_ -|___|  |  |  |__
      |_|___|___|_  |___|   |____/|_____|
                |___|

    """)
  end

end
