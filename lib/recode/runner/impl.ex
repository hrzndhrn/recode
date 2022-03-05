defmodule Recode.Runner.Impl do
  @moduledoc false

  alias Recode.Project

  @behaviour Recode.Runner

  @impl true
  def run({module, opts}, config) do
    project = config |> Keyword.fetch!(:inputs) |> List.wrap() |> Project.new()

    run(project, module, opts, config)
  end

  defp run(project, module, opts, _config) do
    module.run(project, opts)
  end
end
