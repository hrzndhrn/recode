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

    * `-a`, `--autocorrect`, `--no-autocorrect` - Activates/deactivates
      autocrrection. Overwrites the corresponding value in the configuration.

    * `-c`, `--config` - specifies an alternative config file.

    * `-d`, `--dry`, `--no-dry` - Activates/deactivates the dry mode. No file is
      overwritten in dry mode. Overwrites the corresponding value in the
      configuration.

    * `-v`, `--verbose`, `--no-verbose` - Activate/deactivates the verbose mode.
      Overwrites the corresponding value in the configuration.

    * `-t`, `--task`, specifies the task to use. With this option, the task is
      used even if it is specified as `active:  false` in the configuration.
      This option can appear multiple times in a call.

    * `--slowest-tasks` - prints timing information for the N slowest tasks.

    * `--color` - enables color in the output.
  """

  use Mix.Task

  alias Recode.Config
  alias Recode.Runner
  alias Rewrite.DotFormatter

  @opts strict: [
          autocorrect: :boolean,
          color: :boolean,
          config: :string,
          debug: :boolean,
          dry: :boolean,
          task: :keep,
          verbose: :boolean,
          slowest_tasks: :integer
        ],
        aliases: [
          a: :autocorrect,
          c: :config,
          d: :dry,
          t: :task,
          v: :verbose
        ]

  @task_config_keys [
    :active,
    :autocorrect,
    :check,
    :config,
    :exclude,
    :exit_code
  ]

  @impl Mix.Task
  @spec run(list()) :: no_return()
  def run(opts) do
    {:ok, _apps} = Application.ensure_all_started(:recode)

    check_dot_formatter()

    opts = opts!(opts)

    opts =
      opts
      |> Keyword.get(:config, ".recode.exs")
      |> config!()
      |> validate_config!()
      |> validate_tasks!()
      |> update_task_configs!()
      |> merge_opts(opts)
      |> Keyword.put(:cli_opts, acc_tasks(opts))
      |> update(:verbose)
      |> put_debug(opts)

    case Runner.run(opts) do
      {:ok, 0} ->
        exit(:normal)

      {:ok, exit_code} ->
        exit({:shutdown, exit_code})

      {:error, :no_sources} ->
        Mix.raise("No sources found")
    end
  end

  defp merge_opts(config, opts) do
    Keyword.merge(
      config,
      Keyword.take(opts, [:verbose, :autocorrect, :dry, :inputs, :slowest_tasks, :color])
    )
  end

  defp opts!(opts) do
    case OptionParser.parse!(opts, @opts) do
      {opts, []} -> opts
      {opts, inputs} -> Keyword.put(opts, :inputs, inputs)
    end
  end

  defp acc_tasks(opts) do
    tasks =
      Enum.reduce(opts, [], fn {key, value}, acc ->
        case key do
          :task -> [value | acc]
          _else -> acc
        end
      end)

    opts
    |> Keyword.delete(:task)
    |> Keyword.put(:tasks, tasks)
  end

  defp config!(opts) do
    case Config.read(opts) do
      {:ok, config} ->
        config

      {:error, :not_found} ->
        Mix.raise("Config file not found. Run `mix recode.gen.config` to create `.recode.exs`.")
    end
  end

  defp validate_config!(config) do
    case Config.validate(config) do
      :ok ->
        config

      {:error, :out_of_date} ->
        Mix.raise("The config is out of date. Run `mix recode.update.config` to update.")

      {:error, :no_tasks} ->
        Mix.raise("No `:tasks` key found in configuration.")
    end
  end

  defp validate_tasks!(config) do
    Enum.each(config[:tasks], fn {task, config} ->
      task |> Code.ensure_loaded() |> validate_task!(task)
      validate_task_config!(task, config)
    end)

    config
  end

  defp validate_task_config!(task, config) do
    keys = Keyword.keys(config) -- @task_config_keys

    if !Enum.empty?(keys), do: task_config_error!(task, config, keys)
  end

  defp task_config_error!(task, config, keys) do
    config =
      Enum.reduce(keys, config, fn key, config ->
        {value, config} = Keyword.pop!(config, key)

        Keyword.update(config, :config, [{key, value}], fn task_config ->
          Keyword.put(task_config, key, value)
        end)
      end)

    Mix.raise("""
    Invalid config keys #{inspect(keys)} for #{inspect(task)} found.
    Did you want to create a task-specific configuration:
    {#{inspect(task)}, #{inspect(config)}}
    """)
  end

  defp validate_task!({:error, :nofile}, task) do
    Mix.raise("Recode task #{inspect(task)} not found.")
  end

  defp validate_task!({:module, _module}, task) do
    if Recode.Task not in task.__info__(:attributes)[:behaviour] do
      Mix.raise("The module #{inspect(task)} does not implement the Recode.Task behaviour.")
    end
  end

  defp update_task_configs!(config) do
    Keyword.update!(config, :tasks, fn tasks -> do_update_task_configs!(tasks) end)
  end

  defp do_update_task_configs!(tasks) do
    Enum.map(tasks, fn {task, config} ->
      task_config = Keyword.get(config, :config, [])

      case task.init(task_config) do
        {:ok, task_config} ->
          {task, Keyword.put(config, :config, task_config)}

        {:error, message} ->
          Mix.raise("The task #{inspect(task)} has an invalid config:\n#{message}")
      end
    end)
  end

  defp update(opts, :verbose) do
    case opts[:dry] do
      true -> Keyword.put(opts, :verbose, true)
      false -> opts
    end
  end

  defp put_debug(config, opts) do
    debug = Keyword.get(opts, :debug, false)
    Keyword.put(config, :debug, debug)
  end

  defp check_dot_formatter() do
    with true <- File.exists?(".formatter.exs"),
         {:error, reason} <- DotFormatter.read() do
      reason
      |> Exception.message()
      |> Mix.raise()
    end
  end
end
