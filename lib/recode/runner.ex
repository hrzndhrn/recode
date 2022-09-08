defmodule Recode.Runner do
  @moduledoc false

  alias Recode.Runner
  alias Rewrite.Project

  @type config :: keyword()
  @type opts :: keyword()
  @type task :: {module(), opts()}

  @callback run(config) :: Project.t()

  def run(config), do: impl().run(config)

  defp impl, do: Application.get_env(:recode, :runner, Runner.Impl)
end
