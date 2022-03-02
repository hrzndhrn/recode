defmodule Recode.Task.Source do
  @moduledoc """
  TODO: @moduledoc
  """

  @callback run(ast :: Macro.t(), opts :: Keyword.t()) :: Macro.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Recode.Task.Source
    end
  end
end
