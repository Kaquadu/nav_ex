defmodule NavEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :nav_ex,
      version: "0.1.7",
      elixir: "~> 1.18.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),

      # Docs
      name: "NavEx",
      source_url: "https://github.com/Kaquadu/nav_ex",
      docs: [
        # The main page in the docs
        main: "NavEx",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {NavEx.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.7"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:phoenix_live_view, "~> 1.0"}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Kaquadu/nav_ex"}
    ]
  end

  defp description() do
    "NavEx is the navigation history package for Elixir/Phoenix Framework. It uses adapter pattern and lets you choose between a few adapters to keep your users navigation history."
  end
end
