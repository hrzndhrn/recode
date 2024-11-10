defmodule MyCode.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_code,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Recode.Application, []},
    ]
  end

  defp aliases do
    [
      backup: ["cmd elixir ./scripts/backup.exs"],
      "backup.restore": ["cmd elixir ./scripts/backup.exs restore"],
    ]
  end

  defp deps do
    [
      {:recode, path: "../.."},
      # dev/test
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:freedom_formatter, "~> 2.1", only: :dev},
      {:json_formatter, "~> 0.2", only: :dev},
      {:ecto_sql, "~> 3.12", only: :dev},
    ]
  end
end
