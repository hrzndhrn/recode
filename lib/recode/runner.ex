defmodule Recode.Runner do
  @moduledoc false

  alias Recode.Runner
  alias Rewrite.Project

  @type config :: keyword()
  @type opts :: keyword()
  @type task :: {module(), opts()}

  @callback run(config) :: Project.t()
  @callback run(String.t(), config) :: String.t()
  @callback run(String.t(), config, Path.t()) :: String.t()

  def run(config) when is_list(config) do
    impl().run(config)
  end

  def run(content, config, path \\ "source.ex") when is_list(config) do
    impl().run(content, config, path)
  end

  defp impl, do: Application.get_env(:recode, :runner, Runner.Impl)
end
