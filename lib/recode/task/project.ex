defmodule Recode.Task.Project do
  @moduledoc """
  The behaviour for a `recode` task.
  """
  alias Recode.Project

  @callback run(ast :: Project.t(), opts :: Keyword.t()) :: Macro.t()
  @callback type :: :project

  defmacro __using__(_opts) do
    quote do
      @behaviour Recode.Task.Project

      def type, do: :project
    end
  end
end
