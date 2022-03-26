defmodule Recode.Sigils do
  defmacro sigil_z({:<<>>, _, [string]}, []) do
    ast = Code.string_to_quoted!(string)
    {ast, {:_zipper_meta, [if_undefined: :apply], Elixir}}
  end
end

defmodule Recode.Task do
  @moduledoc """
  The behaviour for a `recode` task.
  """
  alias Recode.Project

  @doc """
  Applies a task with the given `project` and `opts`.
  """
  @callback run(project :: Project.t(), opts :: Keyword.t()) :: Project.t()

  @doc """
  Returns the configuration for the given `key`.
  """
  @callback config(key :: :check | :correct | :refactor) :: boolean

  defmacro __using__(opts) do
    quote do
      import Recode.Sigils

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

      defoverridable config: 1
    end
  end
end
