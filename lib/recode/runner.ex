defmodule Recode.Runner do
  @moduledoc false

  alias Recode.Project
  alias Recode.Runner

  @callback run({Project.t(), opts :: keyword()}, config :: keyword()) :: Project.t()

  def run(task, config), do: impl().run(task, config)

  defp impl, do: Application.get_env(:recode, :runner, Runner.Impl)
end
