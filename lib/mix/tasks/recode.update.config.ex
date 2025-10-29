defmodule Mix.Tasks.Recode.Update.Config do
  @shortdoc "Updates an existing config for Recode"

  @moduledoc """
  #{@shortdoc}.

  The task merges the existing config into the actual config and updates the
  version.  Using this task preserves changes in the actual config and adds new values.

  The actual default config:
  ```elixir
  #{Recode.Config.to_string()}
  ```
  """

  use Mix.Task

  @config_filename ".recode.exs"
  @deprecated_configs [:formatter]
  @removed_tasks [Recode.Task.TestFileExt]

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
        |> delete(@deprecated_configs)
        |> Recode.Config.merge()
        |> Recode.Config.delete_tasks(@removed_tasks)

      Mix.Generator.create_file(@config_filename, Recode.Config.to_string(config), force: force)
    else
      Mix.raise(~s|config file #{@config_filename} not found, run "mix recode.gen.config"|)
    end
  end

  defp delete(config, deprecated_configs) do
    Enum.reduce(deprecated_configs, config, fn key, config -> Keyword.delete(config, key) end)
  end
end
