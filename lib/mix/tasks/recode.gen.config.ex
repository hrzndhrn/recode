defmodule Mix.Tasks.Recode.Gen.Config do
  @shortdoc "Generate a new config for Recode"
  @moduledoc @shortdoc

  use Mix.Task

  @doc false
  def run([]) do
    source = :recode |> :code.priv_dir() |> Path.join("config.exs")
    Mix.Generator.copy_file(source, ".config.exs")
  end
end
