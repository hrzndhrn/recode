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

    * `-s`, `--silent` - Activates the silent mode. In silent mode, only issues
      will be printed to the console. Without any issue no output is printed.
      Overwrites the corresponding value in the configuration.

    * `-t`, `--task`, specifies the task to use. With this option, the task is
      used even if it is specified as `active:  false` in the configuration.
      This option can appear multiple times in a call.

    * `--slowest-tasks` - prints timing information for the N slowest tasks.

    * `--color` - enables color in the output. Defaults to `true` if ANSI
      coloring is supported.

    * `--manifest` - enables reading and writing of the `manifest` file.
      Defaults to `true` if the `--task` flag is not given.

    * `--force` - forces a run without reading the `manifest` file. A new
      manifest file is created.
  """

  use Mix.Task

  alias Recode.Config
  alias Recode.Runner
  alias Rewrite.DotFormatter
  alias Rewrite.DotFormatterError

  @opts strict: [
          autocorrect: :boolean,
          color: :boolean,
          config: :string,
          debug: :boolean,
          dry: :boolean,
          force: :boolean,
          manifest: :boolean,
          silent: :boolean,
          slowest_tasks: :integer,
          task: :keep,
          verbose: :boolean
        ],
        aliases: [
          a: :autocorrect,
          c: :config,
          d: :dry,
          s: :silent,
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

    :ok = check_dot_formatter()

    opts = opts!(opts)

    opts =
      opts
      |> Keyword.get(:config, ".recode.exs")
      |> read_config!()
      |> validate_config!()
      |> validate_tasks!()
      |> update_task_configs!()
      |> merge_opts(opts)
      |> Keyword.put(:cli_opts, cli_tasks(opts))
      |> update_verbose()
      |> update_manifest(opts)
      |> put(opts, :debug, false)
      |> put(opts, :force, false)

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
      Keyword.take(opts, [
        :autocorrect,
        :color,
        :dry,
        :inputs,
        :manifest,
        :silent,
        :slowest_tasks,
        :verbose
      ])
    )
  end

  defp opts!(opts) do
    case OptionParser.parse!(opts, @opts) do
      {opts, []} -> opts
      {opts, inputs} -> Keyword.put(opts, :inputs, inputs)
    end
  end

  defp cli_tasks(opts) do
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

  defp read_config!(opts) do
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

    if not Enum.empty?(keys) do
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

  defp update_verbose(config) do
    case config[:dry] do
      true -> Keyword.put(config, :verbose, true)
      false -> config
    end
  end

  defp update_manifest(config, opts) do
    # Updates the manifest configuration based on CLI options and task presence.
    # The manifest is disabled when specific tasks are provided via --task to
    # ensure full task execution regardless of the manifest state.

    manifest? =
      if Keyword.has_key?(opts, :manifest) do
        opts[:manifest]
      else
        Keyword.get(config, :manifest, true)
      end

    opts? = not Keyword.has_key?(opts, :task)

    Keyword.put(config, :manifest, manifest? && opts?)
  end

  defp put(config, opts, key, default) do
    value = Keyword.get(opts, key, default)
    Keyword.put(config, key, value)
  end

  defp check_dot_formatter do
    with true <- File.exists?(".formatter.exs"),
         {:error, reason} <- DotFormatter.read(ignore_missing_sub_formatters: true) do
      reason |> DotFormatterError.message() |> Mix.raise()
    end

    :ok
  end
end
