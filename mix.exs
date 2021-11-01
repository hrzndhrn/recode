defmodule Recode.MixProject do
  use Mix.Project

  def project do
    [
      app: :recode,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_options, "~> 0.3"},
      {:sourceror, "~> 0.8"}
    ]
  end
end
