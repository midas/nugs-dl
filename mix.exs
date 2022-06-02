defmodule NugsDl.MixProject do
  use Mix.Project

  def project do
    [
      app: :nugs_dl,
      version: "0.1.2",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      escript: escript(),
      releases: releases(),
    ]
  end

  def escript do
    [
      main_module: NugsDl.CLI,
      name: "nugs-dl",
      path: "nugs-dl",
      #emu_args: ["-name master@127.0.0.1"],
      #emu_args: ["-sname master -setcookie baz"],
      deps: deps(),
      releases: releases(),
     ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {NugsDl.CLI, []},
      extra_applications: [
        :logger
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bakeware, "~> 0.2"},
      {:burrito, github: "burrito-elixir/burrito"},
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.3"},
      {:optimus, "~> 0.3"},
      {:progress_bar, "~> 2.0"},
      {:tabula, "~> 2.1.1"},
    ]
  end

  def releases do
    [
      nugs_dl: [
        steps: [:assemble, &Bakeware.assemble/1],
        bakeware: [
          compression_level: 1,
          #start_command: "daemon",
        ],
        #steps: [:assemble, &Burrito.wrap/1],
        #burrito: [
          #targets: [
            #macos:   [os: :darwin,  cpu: :x86_64],
            #linux:   [os: :linux,   cpu: :x86_64],
            #windows: [os: :windows, cpu: :x86_64]
          #],
        #],
      ]
    ]
  end

end
