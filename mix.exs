defmodule Recode.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/hrzndhrn/recode"

  def project do
    [
      app: :recode,
      version: "0.1.0",
      elixir: "~> 1.10",
      name: "Recode",
      description: description(),
      docs: docs(),
      source_url: @source_url,
      start_permanent: Mix.env() == :prod,
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "A codre refactoring tool and credo issue solver"
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  def preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.github": :test
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "test/support/plts/dialyzer.plt"},
      flags: [:unmatched_returns]
    ]
  end

  defp deps do
    [
      {:beam_file, "~> 0.3"},
      {:sourceror, "~> 0.10"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Marcus Kruse"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
