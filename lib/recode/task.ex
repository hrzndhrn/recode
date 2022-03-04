defmodule Recode.Task do
  @moduledoc """
  The behaviour for a `recode` task.
  """
  alias Recode.Project

  @callback run(ast :: Project.t(), opts :: Keyword.t()) :: Macro.t()

  defmacro __using__(opts) do
    quote do
      @behaviour Recode.Task

      @opts Map.merge(
              %{
                check: false,
                correct: false,
                refactor: false
              },
              Enum.into(unquote(opts), %{})
            )

      def config(key) when key in [:check, :correct, :refactor] do
        Map.fetch!(@opts, key)
      end
    end
  end
end
