defmodule Mix.Tasks.Recode.Gen.Config do
  use Mix.Task

  @shortdoc "Generate a new config for Recode"
  @moduledoc @shortdoc

  @doc false
  def run([]) do
    source = :recode |> :code.priv_dir() |> Path.join("config.exs")
    Mix.Generator.copy_file(source, ".config.exs")
  end
end
