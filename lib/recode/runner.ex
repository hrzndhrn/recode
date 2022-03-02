defmodule Recode.Runner do
  @moduledoc false

  alias Recode.Project

  def run({task_module, task_opts}, runner_opts) do
    project = runner_opts |> Keyword.fetch!(:inputs) |> List.wrap() |> Project.new()
    type = task_module.type

    run(type, project, task_module, task_opts, runner_opts)
  end

  def run(:project, project, task_module, task_opts, _runner_opts) do
    task_module.run(project, task_opts)
  end
end
