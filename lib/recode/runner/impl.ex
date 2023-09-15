defmodule Recode.Runner.Impl do
  @moduledoc false

  @behaviour Recode.Runner

  alias Recode.Issue
  alias Recode.Task
  alias Rewrite.Source

  @impl true
  def run(config) when is_list(config) do
    config
    |> tasks()
    |> do_run(update_config(config))
  end

  @impl true
  def run(content, config, path \\ "source.ex") do
    source = Source.Ex.from_string(content, path)

    config
    |> tasks()
    |> do_run(update_config(config), source)
    |> Source.get(:content)
    |> eof()
  end

  defp do_run(tasks, config) do
    project =
      config
      |> project()
      |> format(:project, config)

    tasks
    |> update_opts(config)
    |> correst_first()
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
    |> filter(get_cli_opts(config, :tasks, []))
    |> Enum.reduce(project, fn {module, opts}, project ->
      Rewrite.map!(project, fn source ->
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

  defp get_cli_opts(config, key, default) do
    config
    |> Keyword.get(:cli_opts, [])
    |> Keyword.get(key, default)
  end

  defp filter(tasks, []), do: tasks

  defp filter(tasks, selected) do
    Enum.reduce(tasks, [], fn {module, opts}, acc ->
      name = inspect(module)
      take = Enum.any?(selected, fn item -> String.ends_with?(name, ".#{item}") end)

      case take do
        true -> [{module, Keyword.delete(opts, :active)} | acc]
        false -> acc
      end
    end)
  end

  defp format(%Rewrite{} = project, label, config, info \\ nil) do
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
    if Keyword.has_key?(config, :project) do
      config[:project]
    else
      inputs = config |> Keyword.fetch!(:inputs) |> List.wrap()

      if inputs == ["-"] do
        stdin = IO.stream(:stdio, :line) |> Enum.to_list() |> IO.iodata_to_binary()

        stdin |> Source.Ex.from_string("nofile") |> List.wrap() |> Rewrite.from_sources!()
      else
        Rewrite.new!(inputs, [{Source, owner: Recode},{Source.Ex, exclude_plugins: Recode.FormatterPlugin}])
      end
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
    |> tasks(:autocorrect, config[:autocorrect])
    |> tasks(:check, Keyword.get(config, :check, true))
  end

  defp tasks(tasks, :autocorrect, autocorrect) do
    case autocorrect do
      false -> Enum.filter(tasks, fn {task, _opts} -> Task.checker?(task) end)
      true -> tasks
    end
  end

  defp tasks(tasks, :check, false) do
    Enum.reject(tasks, fn {task, _opts} ->
      Task.checker?(task) && !Task.corrector?(task)
    end)
  end

  defp tasks(tasks, :check, true), do: tasks

  defp tasks(tasks, :active) do
    Enum.filter(tasks, fn {_task, config} -> Keyword.get(config, :active, true) end)
  end

  defp correst_first(tasks) do
    groups =
      Enum.group_by(tasks, fn {task, opts} ->
        Task.corrector?(task) && Keyword.get(opts, :autocorrect)
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
end
