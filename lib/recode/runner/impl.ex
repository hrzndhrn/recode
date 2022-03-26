defmodule Recode.Runner.Impl do
  @moduledoc false

  @behaviour Recode.Runner

  alias Recode.Project

  @impl true
  def run(tasks, config) when is_list(tasks) do
    project = project(config)

    tasks
    |> run_tasks(project, config)
    |> format(config)
  end

  def run({module, opts}, config) do
    run([{module, opts}], config)
  end

  defp run_tasks(tasks, project, config) do
    Enum.reduce(tasks, project, fn {module, opts}, project ->
      run_task(project, module, opts, config)
    end)
  end

  defp run_task(%Project{} = project, module, opts, config) do
    opts = Keyword.put_new(opts, :autocorrect, config[:autocorrect])
    module.run(project, opts)
  end

  defp format(project, config) do
    case Keyword.fetch(config, :formatter) do
      {:ok, {formatter, opts}} -> formatter.format(project, opts, config)
      :error -> project
    end
  end

  defp project(config) do
    config |> Keyword.fetch!(:inputs) |> List.wrap() |> Project.new()
  end
end
