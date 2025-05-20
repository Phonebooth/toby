defmodule Toby.Mixfile do
  use Mix.Project

  def project do
    [
      app: :toby,
      version: "0.2.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Toby, []},
      extra_applications: [:logger],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ratatouille, "~> 0.5"},
      {:distillery, "~> 2.0", runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:libcluster, "~> 3.5.0"},
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end
end
