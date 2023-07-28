defmodule Mix.Tasks.Recode.Gen.Config do
  @shortdoc "Generates a new config for Recode"

  @moduledoc """
  #{@shortdoc}. Writes the file `.recode.exs` in the root directory of the mix
  project.

  The default config:
  ```elixir
  #{Recode.Config.to_string()}
  ```
  """

  use Mix.Task

  @impl true
  def run([]) do
    Mix.Generator.create_file(".recode.exs", Recode.Config.to_string())
  end
end
