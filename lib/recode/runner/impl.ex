defmodule Recode.Runner.Impl do
  @moduledoc false

  @behaviour Recode.Runner

  alias Recode.EventManager
  alias Recode.Issue
  alias Recode.Manifest
  alias Recode.Timestamp
  alias Rewrite.DotFormatter
  alias Rewrite.Source

  @impl true
  def run(config) when is_list(config) do
    start_recode = time()

    tasks = tasks(config)

    dot_formatter = dot_formatter()

    config =
      config
      |> update_config(dot_formatter)
      |> start_event_manager()

    project =
      config
      |> project(dot_formatter)
      |> notify(:prepared, config, time(start_recode))
      |> format(config)

    start_tasks = time()

    tasks
    |> update_opts(config)
    |> correctors_first()
    |> run_tasks(project, config)
    |> notify(:tasks_finished, config, time(start_tasks))
    |> tap(fn project -> write(project, config) end)
    |> tap(fn project -> Manifest.write(project, config) end)
    |> notify(:finished, config, time(start_recode))
    |> tap(fn _project -> stop_event_manager(config) end)
    |> then(fn project ->
      case Enum.empty?(project.sources) and Enum.empty?(project.excluded) do
        true -> {:error, :no_sources}
        false -> {:ok, exit_code(project, tasks)}
      end
    end)
  end

  @impl true
  def run(content, config, path \\ "source.ex") do
    tasks = tasks(config)
    formatter_opts = Keyword.get(config, :formatter_opts, [])

    dot_formatter =
      DotFormatter.from_formatter_opts(formatter_opts, remove_plugins: [Recode.FormatterPlugin])

    config = update_config(config, dot_formatter)

    source =
      content
      |> Source.Ex.from_string(path: path)
      |> Source.format!(by: Recode.Task.Format, dot_formatter: dot_formatter)

    %Source{filetype: %Source.Ex{}} = source

    tasks
    |> update_opts(config)
    |> correctors_first()
    |> Enum.reduce(source, fn {module, opts}, source ->
      case exclude?(module, source, config) do
        true ->
          source

        false ->
          module.run(source, Keyword.put(opts, :dot_formatter, dot_formatter))
      end
    end)
    |> Source.get(:content)
    |> eof()
  end

  defp format(project, config) do
    project = Rewrite.format!(project, by: Recode.Task.Format)

    if config[:dry] do
      Rewrite.map!(project, fn source ->
        if Source.updated?(source) do
          source
          |> Source.undo()
          |> Source.add_issue(Issue.new(Recode.Task.Format, "The file is not formatted."))
        else
          source
        end
      end)
    else
      project
    end
  end

  defp exit_code(project, tasks) do
    exit_codes =
      Enum.into(tasks, %{}, fn {task, config} -> {task, Keyword.get(config, :exit_code, 1)} end)

    Enum.reduce(Rewrite.sources(project), 0, fn source, exit_code ->
      source
      |> Source.issues()
      |> Enum.reduce(exit_code, fn issue, exit_code ->
        Bitwise.bor(exit_code, Map.get(exit_codes, issue.reporter, 1))
      end)
    end)
  end

  defp start_event_manager(config) do
    {:ok, event_manager} = EventManager.start_link()

    for formatter <- Keyword.fetch!(config, :formatters) do
      _formatter =
        with {:error, error} <- EventManager.add_handler(event_manager, formatter, config) do
          raise "Can not initialise formatter #{inspect(formatter)}. reason: #{inspect(error)}"
        end
    end

    Keyword.put(config, :event_manager, event_manager)
  end

  defp stop_event_manager(config) do
    config |> event_manager() |> EventManager.stop()
  end

  defp run_tasks(tasks, project, config) do
    dot_formatter = Rewrite.dot_formatter(project)
    runner = runner(tasks, config, dot_formatter)

    sources = Stream.map(project.sources, fn {_path, source} -> source end)

    sources =
      Recode.TaskSupervisor
      |> Task.Supervisor.async_stream(sources, runner, zip_input_on_exit: true)
      |> Stream.map(&result/1)
      |> Enum.into(%{})

    %{project | sources: sources}
  end

  defp result({:ok, source}), do: {source.path, source}

  defp result({:exit, {source, {error, stacktrace}}}) when is_exception(error) do
    source =
      Source.add_issue(
        source,
        Issue.new(
          Recode.Runner,
          task: Recode.Runner,
          error: error,
          message: Exception.format(:error, error, stacktrace)
        )
      )

    {source.path, source}
  end

  defp runner(tasks, config, dot_formatter) do
    fn source ->
      Enum.reduce(tasks, source, fn task, source ->
        run_task(task, source, config, dot_formatter)
      end)
    end
  end

  defp run_task({task_module, task_config}, source, config, dot_formatter) do
    case exclude?(task_module, source, config) do
      true ->
        source

      false ->
        start = time()

        source
        |> notify(:task_started, config, task_module)
        |> task_module.run(Keyword.put(task_config, :dot_formatter, dot_formatter))
        |> notify(:task_finished, config, {task_module, time(start)})
    end
  rescue
    error in ExUnit.AssertionError ->
      reraise error, __STACKTRACE__

    error ->
      Source.add_issue(
        source,
        Issue.new(
          Recode.Runner,
          message: Exception.format(:error, error, __STACKTRACE__),
          meta: [task: task_module, error: error]
        )
      )
  end

  # For now, all sources without a filetype Source.Ex are direclty excluded.
  # For the Source.Ex sources we check whether the source is excluded.
  defp exclude?(task, %Source{filetype: %Source.Ex{}} = source, config) do
    config
    |> config(task, :exclude)
    |> Enum.any?(fn glob -> GlobEx.match?(glob, source.path) end)
  end

  defp exclude?(_task, _source, _config), do: true

  defp get_cli_opts(config, key, default), do: config[:cli_opts][key] || default

  defp notify(data, event, config, {meta, time}) when is_atom(event) do
    do_notify(data, {event, data, meta, time}, config)
  end

  defp notify(data, event, config, meta) when is_atom(event) do
    do_notify(data, {event, data, meta}, config)
  end

  defp do_notify(data, event, config) do
    config
    |> event_manager()
    |> EventManager.notify(event)

    data
  end

  defp event_manager(config), do: Keyword.fetch!(config, :event_manager)

  defp project(config, dot_formatter) do
    inputs = Keyword.fetch!(config, :inputs)

    if inputs == ["-"] do
      :stdio
      |> IO.stream(:line)
      |> Enum.to_list()
      |> IO.iodata_to_binary()
      |> Source.Ex.from_string(path: "nofile.ex")
      |> List.wrap()
      |> Rewrite.from_sources!()
    else
      Rewrite.new!(inputs,
        filetypes: [Source.Ex, {Source, owner: Recode}],
        dot_formatter: dot_formatter,
        exclude: exclude_reading(config)
      )
    end
  end

  defp exclude_reading(config) do
    config_file = get_cli_opts(config, :config, ".recode.exs")
    config_timestemp = Timestamp.for_file(config_file)

    case Manifest.read(config) do
      {timestamp, ^config_file, paths} when timestamp > config_timestemp ->
        fn path ->
          cond do
            path in paths -> false
            Timestamp.for_file(path) > timestamp -> false
            true -> true
          end
        end

      _else ->
        fn _path -> false end
    end
  end

  defp dot_formatter do
    if File.exists?(".formatter.exs") do
      case DotFormatter.read(remove_plugins: [Recode.FormatterPlugin]) do
        {:ok, dot_formatter} ->
          dot_formatter

        {:error, error} ->
          Mix.raise("Failed to read formatter: #{inspect(error)}")
      end
    else
      DotFormatter.default()
    end
  end

  defp config(config, task) do
    config
    |> Keyword.fetch!(:tasks)
    |> Keyword.fetch!(task)
  end

  defp config(config, task, key) do
    config |> config(task) |> Keyword.fetch!(key)
  end

  defp tasks(config) do
    config
    |> Keyword.fetch!(:tasks)
    |> tasks_selected(get_cli_opts(config, :tasks, []))
    |> tasks_active()
    |> tasks_autocorrect(config[:autocorrect])
    |> tasks_check(config[:check])
  end

  defp tasks_selected(tasks, []), do: tasks

  defp tasks_selected(tasks, selected) do
    tasks
    |> Enum.reduce([], tasks_selected(selected))
    |> Enum.reverse()
  end

  defp tasks_selected(selected) do
    fn {module, opts}, acc ->
      name = inspect(module)
      take = Enum.any?(selected, fn item -> String.ends_with?(name, ".#{item}") end)

      case take do
        true -> [{module, Keyword.delete(opts, :active)} | acc]
        false -> acc
      end
    end
  end

  defp tasks_autocorrect(tasks, autocorrect) do
    case autocorrect do
      false -> Enum.filter(tasks, fn {task, _opts} -> Recode.Task.checker?(task) end)
      true -> tasks
    end
  end

  defp tasks_check(tasks, false) do
    Enum.reject(tasks, fn {task, _opts} ->
      Recode.Task.checker?(task) && !Recode.Task.corrector?(task)
    end)
  end

  defp tasks_check(tasks, _truthy), do: tasks

  defp tasks_active(tasks) do
    Enum.filter(tasks, fn {_task, config} -> Keyword.get(config, :active, true) end)
  end

  defp correctors_first(tasks) do
    groups =
      Enum.group_by(tasks, fn {task, opts} ->
        Recode.Task.corrector?(task) && Keyword.get(opts, :autocorrect)
      end)

    Enum.concat(Map.get(groups, true, []), Map.get(groups, false, []))
  end

  defp update_config(config, dot_formatter) do
    config
    |> Keyword.update!(:tasks, fn tasks -> update_tasks(tasks) end)
    |> Keyword.update!(:inputs, fn inputs -> update_inputs(inputs, dot_formatter) end)
  end

  # Updates the tasks configuration by expanding globs in the :exclude option.
  defp update_tasks(tasks) do
    Enum.map(tasks, fn {task, config} ->
      config = Keyword.update(config, :exclude, [], &compile_globs/1)

      {task, config}
    end)
  end

  # Updates the list of inputs by expanding the :formatter atom to include
  # paths from dot_formatter configuration when available.
  defp update_inputs(inputs, dot_formatter) do
    inputs
    |> List.wrap()
    |> Enum.flat_map(fn
      :formatter -> if dot_formatter.path, do: DotFormatter.inputs(dot_formatter), else: []
      input -> [input]
    end)
  end

  defp compile_globs(exclude) do
    exclude
    |> List.wrap()
    |> Enum.map(fn exclude -> GlobEx.compile!(exclude, match_dot: true) end)
  end

  defp update_opts(tasks, config) do
    Enum.map(tasks, fn {task, task_config} ->
      opts =
        task_config
        |> Keyword.get(:config, [])
        |> update_autocorrect(config, task_config)

      {task, opts}
    end)
  end

  defp update_autocorrect(opts, config, task_config) do
    cli_opts = Keyword.get(config, :cli_opts, [])

    autocorrect =
      cond do
        Keyword.has_key?(cli_opts, :autocorrect) -> Keyword.get(cli_opts, :autocorrect)
        Keyword.has_key?(task_config, :autocorrect) -> Keyword.get(task_config, :autocorrect)
        true -> Keyword.get(config, :autocorrect, true)
      end

    Keyword.put(opts, :autocorrect, autocorrect)
  end

  defp write(project, config) do
    case Keyword.fetch!(config, :dry) do
      true -> project
      false -> write(project)
    end
  end

  defp write(project) do
    with {:error, errors, _project} <- Rewrite.write_all(project) do
      Enum.each(errors, fn error ->
        error |> Exception.message() |> Mix.Shell.IO.error()
      end)
    end
  end

  defp eof(""), do: ""

  defp eof(string), do: String.trim_trailing(string, "\n") <> "\n"

  defp time, do: System.monotonic_time()

  defp time(time) do
    System.convert_time_unit(System.monotonic_time() - time, :native, :microsecond)
  end
end
