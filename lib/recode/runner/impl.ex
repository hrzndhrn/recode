defmodule Recode.Runner.Impl do
  @moduledoc false

  @behaviour Recode.Runner

  alias Recode.Issue
  alias Rewrite.Project
  alias Rewrite.Source

  @impl true
  def run(config) when is_list(config) do
    config
    |> tasks()
    |> do_run(update_config(config))
  end

  @impl true
  def run(content, config, path \\ "source.ex") do
    source = Source.from_string(content, path)

    config
    |> tasks()
    |> do_run(update_config(config), source)
    |> Source.code()
    |> eof()
  end

  defp do_run(tasks, config) do
    project =
      config
      |> project()
      |> format(:project, config)

    tasks
    |> update_opts(config)
    |> run_tasks(project, config)
    |> format(:tasks_ready, config)
    |> format(:results, config)
    |> tap(fn project -> write(project, config) end)
  end

  def do_run(tasks, config, source) do
    tasks
    |> update_opts(config)
    |> Enum.reduce(source, fn {module, opts}, source ->
      case exclude?(module, source, config) do
        true -> source
        false -> module.run(source, opts)
      end
    end)
  end

  defp run_tasks(tasks, project, config) do
    tasks
    |> filter(Keyword.get(config, :task, :all))
    |> Enum.reduce(project, fn {module, opts}, project ->
      Project.map(project, fn source ->
        run_task(source, project, config, module, opts)
      end)
    end)
  end

  defp run_task(source, project, config, module, opts) do
    case exclude?(module, source, config) do
      true ->
        source

      false ->
        _project = format(project, :task, config, {source, module, opts})
        module.run(source, opts)
    end
  rescue
    error ->
      Source.add_issue(
        source,
        Issue.new(
          Recode.Runner,
          task: module,
          error: error,
          message: Exception.format(:error, error, __STACKTRACE__)
        )
      )
  end

  defp exclude?(task, source, config) do
    config
    |> config(task, :exclude)
    |> Enum.any?(fn glob -> GlobEx.match?(glob, source.path) end)
  end

  defp filter(tasks, :all), do: tasks

  defp filter(tasks, task) do
    tasks
    |> Enum.filter(fn {module, _opts} ->
      module |> inspect() |> String.ends_with?(".#{task}")
    end)
    |> Enum.map(fn {module, opts} ->
      {module, Keyword.delete(opts, :active)}
    end)
  end

  defp format(%Project{} = project, label, config, info \\ nil) do
    case Keyword.fetch(config, :formatter) do
      {:ok, {formatter, opts}} ->
        do_format(formatter, label, project, opts, config, info)
        project

      :error ->
        project
    end
  end

  defp do_format(formatter, label, project, opts, config, nil) do
    formatter.format(label, {project, config}, opts)
  end

  defp do_format(formatter, label, project, opts, config, info) do
    formatter.format(label, {project, config}, info, opts)
  end

  defp project(config) do
    inputs = config |> Keyword.fetch!(:inputs) |> List.wrap()

    if inputs == ["-"] do
      stdin = IO.stream(:stdio, :line) |> Enum.to_list() |> IO.iodata_to_binary()

      stdin |> Source.from_string() |> List.wrap() |> Project.from_sources()
    else
      Project.read!(inputs)
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
    |> tasks(:active)
    |> tasks(:correct_first)
    |> tasks(:autocorrect, config[:autocorrect])
  end

  defp tasks(tasks, :autocorrect, autocorrect) do
    case autocorrect do
      false -> Enum.filter(tasks, fn {task, _opts} -> task.config(:check) end)
      true -> tasks
    end
  end

  defp tasks(tasks, :active) do
    Enum.filter(tasks, fn {_task, config} -> Keyword.get(config, :active, true) end)
  end

  defp tasks(tasks, :correct_first) do
    groups =
      Enum.group_by(tasks, fn {task, _opts} ->
        task.config(:correct)
      end)

    Enum.concat(Map.get(groups, true, []), Map.get(groups, false, []))
  end

  defp update_config(config) do
    Keyword.update!(config, :tasks, fn tasks -> update_config(tasks, :exclude) end)
  end

  defp update_config(tasks, :exclude) do
    Enum.map(tasks, fn {task, config} ->
      config = Keyword.update(config, :exclude, [], &compile_globs/1)

      {task, config}
    end)
  end

  defp compile_globs(exclude) do
    exclude
    |> List.wrap()
    |> Enum.map(fn exclude -> GlobEx.compile!(exclude, match_dot: true) end)
  end

  defp update_opts(tasks, config) do
    Enum.map(tasks, fn {task, task_config} ->
      opts = Keyword.get(task_config, :config, [])

      opts = Keyword.put_new(opts, :autocorrect, config[:autocorrect])

      {task, opts}
    end)
  end

  defp write(project, config) do
    case Keyword.fetch!(config, :dry) do
      true -> project
      false -> write(project)
    end
  end

  defp write(project) do
    exclude = project |> Project.conflicts() |> Map.keys()

    with {:error, errors} <- Project.save(project, exclude) do
      Enum.each(errors, fn {file, reason} ->
        Mix.Shell.IO.error("Writing file #{file} fails, reason: #{inspect(reason)}")
      end)
    end
  end

  defp eof(""), do: ""

  defp eof(string), do: String.trim_trailing(string, "\n") <> "\n"
end
