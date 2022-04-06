defmodule Mix.Tasks.Recode.Gen.Config do
  @shortdoc "Generates a new config for Recode"

  @moduledoc """
  #{@shortdoc}. Writes the file `.recode.exs` in the root directory of the mix
  project.

  The default config:
  ```elixir
  #{File.read!("priv/config.exs")}
  ```
  """

  use Mix.Task

  @config ".recode.exs"

  @doc false
  def run([]) do
    Mix.Generator.copy_file(source(), @config)
  end

  defp source, do: :recode |> :code.priv_dir() |> Path.join("config.exs")
end
