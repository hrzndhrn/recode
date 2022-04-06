defmodule Recode.Runner.Impl do
  @moduledoc false

  @behaviour Recode.Runner

  alias Recode.Project

  @impl true
  def run(config) do
    config
    |> tasks()
    |> run(config)
  end

  @impl true
  def run(tasks, config) when is_list(tasks) do
    project =
      config
      |> project()
      |> format(:project, config)

    tasks
    |> run_tasks(project)
    |> format(:results, config)
    |> write(config)
  end

  def run({module, opts}, config) do
    run([{module, opts}], config)
  end

  defp run_tasks(tasks, project) do
    Enum.reduce(tasks, project, fn {module, opts}, project ->
      run_task(project, module, opts)
    end)
  end

  defp run_task(%Project{} = project, module, opts) do
    Project.map(project, fn source -> module.run(source, opts) end)
  end

  defp format(project, label, config) do
    case Keyword.fetch(config, :formatter) do
      {:ok, {formatter, opts}} -> format(formatter, label, project, opts, config)
      :error -> project
    end
  end

  defp format(formatter, label, project, opts, config) do
    formatter.format(label, project, opts, config)

    project
  end

  defp project(config) do
    config |> Keyword.fetch!(:inputs) |> List.wrap() |> Project.new()
  end

  defp tasks(config) do
    config
    |> Keyword.fetch!(:tasks)
    |> tasks(:correct_first)
    |> tasks(:filter, config)
    |> update_opts(config)
  end

  defp tasks(tasks, :filter, config) do
    case config[:autocorrect] do
      false -> Enum.filter(tasks, fn {task, _opts} -> task.config(:check) end)
      true -> tasks
    end
  end

  defp tasks(tasks, :correct_first) do
    groups =
      Enum.group_by(tasks, fn {task, _opts} ->
        task.config(:correct)
      end)

    Enum.concat(Map.get(groups, true, []), Map.get(groups, false, []))
  end

  defp update_opts(tasks, config) do
    Enum.map(tasks, fn {task, opts} ->
      opts = Keyword.put_new(opts, :autocorrect, config[:autocorrect])
      {task, opts}
    end)
  end

  defp write(project, config) do
    case Keyword.fetch!(config, :dry) do
      true ->
        project

      false ->
        write(project)
    end
  end

  defp write(project) do
    with {:error, errors} <- Project.write(project, exclude: :conflicts) do
      Enum.each(errors, fn {file, reason} ->
        Mix.Shell.IO.error("Writing file #{file} fails, reason: #{inspect(reason)}")
      end)
    end

    project
  end
end
