defmodule Mix.Tasks.Recode.Update.Config do
  @shortdoc "Updates an existing config for Recode"

  @moduledoc """
  #{@shortdoc}.

  The task merges the exsiting config into the actual config and updates the
  version.  Using this task preserves changes in the actual config and adds new values.

  The acutal default config:
  ```elixir
  #{Recode.Config.to_string()}
  ```
  """

  use Mix.Task

  @config_filename ".recode.exs"

  @doc false
  def run([]), do: do_run(false)
  def run(["--force"]), do: do_run(true)
  def run(opts), do: Mix.raise("get unknown options: #{inspect(opts)}")

  defp do_run(force) do
    if File.exists?(@config_filename) do
      config =
        @config_filename
        |> Code.eval_file()
        |> elem(0)
        |> merge(Recode.Config.default())

      Mix.Generator.create_file(@config_filename, Recode.Config.to_string(config), force: force)
    else
      Mix.raise(~s|config file #{@config_filename} not found, run "mix recode.gen.config"|)
    end
  end

  defp merge(old, new) do
    tasks = new[:tasks] |> Keyword.merge(old[:tasks]) |> Enum.sort()

    new
    |> Keyword.merge(old)
    |> Keyword.merge(version: new[:version], tasks: tasks)
  end
end
