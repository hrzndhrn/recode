defmodule Recode.Task do
  @moduledoc """
  The behaviour for a `recode` task.
  """

  alias Rewrite.Source

  @doc """
  Applies a task with the given `source` and `opts`.
  """
  @callback run(source :: Source.t(), opts :: Keyword.t()) :: Source.t()

  @doc """
  Returns the configuration for the given `key`.
  """
  @callback config(key :: :check | :correct | :refactor) :: boolean

  @optional_callbacks config: 1

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

      @doc false
      def config(key) when key in [:check, :correct, :refactor] do
        Map.fetch!(@opts, key)
      end
    end
  end
end
