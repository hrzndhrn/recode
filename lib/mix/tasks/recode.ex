defmodule Mix.Tasks.Recode do
  @shortdoc "Runs the linter"

  @moduledoc """
  #{@shortdoc}.

  ```shell
  > mix recode [options] [inputs]
  ```

  Without a `inputs` argument the `inputs` value from the config is used. The
  `inputs` argument accepts a wildcard.

  If `inputs` value is `-`, then the input is read from stdin.

  Without the option `--config file` the config file `.recode.exs` is used. A
  default `.recode.exs` can be generated with `mix recode.gen.config`.

  ## Command line Option

    * `--autocorrect`, `--no-autocorrect` - Activates/deactivates autocrrection.
      Overwrites the corresponding value in the configuration.

    * `--config` - specifies an alternative config file.

    * `--dry`, `--no-dry` - Activates/deactivates the dry mode. No file is
      overwritten in dry mode. Overwrites the corresponding value in the
      configuration.

    * `--verbose`, `--no-verbose` - Activate/deactivates the verbose mode.
      Overwrites the corresponding value in the configuration.

    * `--task`, specifies the task to use. With this option, the task is used
      even if it is specified as `active:  false` in the configuration.
  """

  use Mix.Task

  alias Recode.Config
  alias Recode.Runner
  alias Rewrite.Project

  @opts strict: [
          autocorrect: :boolean,
          dry: :boolean,
          verbose: :boolean,
          config: :string,
          task: :string
        ]

  @impl Mix.Task
  @spec run(list()) :: no_return()
  def run(opts) do
    opts = opts!(opts)

    opts
    |> config!()
    |> validate_config!()
    |> Keyword.merge(opts)
    |> update(:verbose)
    |> Runner.run()
    |> output()
  end

  @spec output(Project.t()) :: no_return()
  defp output(%Project{sources: sources}) when map_size(sources) == 0 do
    Mix.raise("No sources found")
  end

  defp output(%Project{} = project) do
    case Project.issues?(project) do
      true -> exit({:shutdown, 1})
      false -> exit(:normal)
    end
  end

  defp opts!(opts) do
    case OptionParser.parse!(opts, @opts) do
      {opts, []} -> opts
      {opts, inputs} -> Keyword.put(opts, :inputs, inputs)
    end
  end

  defp config!(opts) do
    case Config.read(opts) do
      {:ok, config} ->
        config

      {:error, :not_found} ->
        Mix.raise("Config file not found. Run `mix recode.get.config` to create `.recode.exs`.")
    end
  end

  defp validate_config!(config) do
    case Config.validate(config) do
      :ok ->
        config

      {:error, :out_of_date} ->
        Mix.raise("The config is out of date. Run `mix recode.gen.config` to update.")

      {:error, :no_tasks} ->
        Mix.raise("No `:tasks` key found in configuration.")
    end
  end

  defp update(opts, :verbose) do
    case opts[:dry] do
      true -> Keyword.put(opts, :verbose, true)
      false -> opts
    end
  end
end
