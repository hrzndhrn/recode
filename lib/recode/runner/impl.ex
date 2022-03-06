defmodule Recode.Runner.Impl do
  @moduledoc false

  alias Recode.Project

  @behaviour Recode.Runner

  @impl true
  def run({module, opts}, config) do
    project = config |> Keyword.fetch!(:inputs) |> List.wrap() |> Project.new()

    project
    |> run(module, opts, config)
    |> format(config)
  end

  def run(tasks, config) do
    project = config |> Keyword.fetch!(:inputs) |> List.wrap() |> Project.new()

    tasks
    |> Enum.reduce(project, fn {module, opts}, project ->
      run(project, module, opts, config)
    end)
    |> format(config)
  end

  defp run(project, module, opts, _config) do
    module.run(project, opts)
  end

  defp format(project, config) do
    case Keyword.fetch(config, :formatter) do
      {:ok, {formatter, opts}} -> formatter.format(project, opts, config)
      :error -> project
    end
  end
end
