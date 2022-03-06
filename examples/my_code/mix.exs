defmodule MyCode.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_code,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      backup: ["run scripts/backup.exs"],
      "backup.apply": ["run scripts/backup.exs apply"]
    ]
  end

  defp deps do
    [
      {:recode, path: "../.."}
    ]
  end
end
