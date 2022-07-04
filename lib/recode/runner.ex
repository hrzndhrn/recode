defmodule Recode.Runner do
  @moduledoc false

  alias Recode.Project
  alias Recode.Runner

  @type config :: keyword()
  @type opts :: keyword()
  @type task :: {module(), opts()}

  @callback run(config) :: Project.t()
  @callback run(task() | [task()], config) :: Project.t()

  def run(config), do: impl().run(config)
  def run(task, config), do: impl().run(task, config)

  defp impl, do: Application.get_env(:recode, :runner, Runner.Impl)
end
