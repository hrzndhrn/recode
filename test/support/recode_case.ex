defmodule RecodeCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Recode.Project
  alias Recode.Runner
  alias Recode.Source

  using do
    quote do
      import RecodeCase
    end
  end

  setup context do
    Mox.stub_with(Recode.RunnerMock, Recode.Runner.Impl)

    context
  end

  def run_task({task, opts}, config) do
    Runner.run({task, opts}, config)
  end

  def run_task_with_sources({task, opts}, sources) do
    sources = Enum.map(sources, &Source.from_code/1)

    project =
      sources
      |> Project.from_sources()
      |> task.run(opts)

    Enum.map(sources, fn %{id: id} ->
      project
      |> Project.source_by_id!(id)
      |> Source.code()
    end)
  end
end
