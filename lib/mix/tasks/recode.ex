defmodule Mix.Tasks.Recode do
  @shortdoc "TODO: add shortdoc"

  @moduledoc """
  TODO: add moduledoc
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
    groups =
      Enum.group_by(opts[:tasks], fn {task, _opts} ->
        task.config(:correct)
      end)

    tasks = Enum.concat(Map.get(groups, true, []), Map.get(groups, false, []))

    Keyword.put(opts, :tasks, tasks)
  end
end
