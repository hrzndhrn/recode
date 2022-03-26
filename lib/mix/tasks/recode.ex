defmodule Mix.Tasks.Recode do
  @shortdoc "Runs the linter"

  @moduledoc """
  #{@shortdoc}.

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
  """

  use Mix.Task

  alias Recode.Config
  alias Recode.DotFormatter
  alias Recode.Runner

  @opts strict: [autocorrect: :boolean, dry: :boolean, verbose: :boolean, config: :string]

  @impl Mix.Task
  def run(opts) do
    opts = opts!(opts)
    config = config!(opts)

    config =
      config
      |> Keyword.merge(opts)
      |> update(:verbose)
      |> update(:locals_without_parens)
      |> update(:tasks)

    {tasks, config} = Keyword.pop!(config, :tasks)

    Runner.run(tasks, config)
  end

  defp opts!(opts) do
    case OptionParser.parse!(opts, @opts) do
      {opts, []} -> opts
      {_opts, args} -> Mix.raise("#{inspect(args)} : Unknown")
    end
  end

  defp config!(opts) do
    case Config.read(opts) do
      {:ok, config} -> config
      {:error, :not_found} -> Mix.raise("Config file not found")
    end
  end

  defp update(opts, :verbose) do
    case opts[:dry] do
      true -> Keyword.put(opts, :verbose, true)
      false -> opts
    end
  end

  defp update(opts, :locals_without_parens) do
    Keyword.put(opts, :locals_without_parens, DotFormatter.locals_without_parens())
  end

  defp update(opts, :tasks) do
    tasks =
      opts
      |> Keyword.fetch!(:tasks)
      |> update_tasks(:correct_first)
      |> update_tasks(:filter, opts)

    Keyword.put(opts, :tasks, tasks)
  end

  @deprecated "asdf"
  defp update_tasks(tasks, :filter, opts) do
    case opts[:autocorrect] do
      false -> Enum.filter(tasks, fn {task, _opts} -> task.config(:check) end)
      true -> tasks
    end
  end

  defp update_tasks(tasks, :correct_first) do
    groups =
      Enum.group_by(tasks, fn {task, _opts} ->
        task.config(:correct)
      end)

    Enum.concat(Map.get(groups, true, []), Map.get(groups, false, []))
  end
end
