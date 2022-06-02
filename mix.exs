defmodule NugsDl.MixProject do
  use Mix.Project

  def project do
    [
      app: :nugs_dl,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      escript: escript(),
      deps: deps()
    ]
  end

  def escript do
    [
      main_module: NugsDl.CLI,
      name: "nugs-dl",
      path: "nugs-dl",
      #emu_args: ["-name master@127.0.0.1"],
      #emu_args: ["-sname master -setcookie baz"],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :logger
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
    ]
  end
end
