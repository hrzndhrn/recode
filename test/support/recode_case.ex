defmodule RecodeCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Recode.Project
  alias Recode.Source

  using do
    quote do
      import RecodeCase
    end
  end

  def run_task({task, opts}, config) do
    project =
      case Keyword.has_key?(config, :sources) do
        true ->
          config
          |> Keyword.fetch!(:sources)
          |> Enum.map(&Source.from_code/1)
          |> Project.from_sources()

        false ->
          Project.new(config[:inputs])
      end

    task.run(project, opts)
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
