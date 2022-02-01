defmodule Recode.Task do
  @moduledoc """
  The behaviour for a `recode` task.
  """

  @callback run(ast :: Macro.t(), opts :: Keyword.t()) :: Macro.t()

  defmacro __using__(_opts) do
    quote do
      alias Sourceror.Zipper

      @spec run(ast :: Macro.t()) :: Macro.t()
      def run(ast), do: run(ast, [])
    end
  end
end
