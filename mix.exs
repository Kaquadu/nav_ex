defmodule NavEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :nav_ex,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:plug_cowboy, "~> 2.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
