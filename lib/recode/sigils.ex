defmodule Recode.Sigils do
  @moduledoc """
  This module provides the sigil `~z`.
  """

  @doc """
  The sigil `~z` creates a zipper tuple that ignores the meta part.
  """
  @spec sigil_z(tuple(), list()) :: Macro.t()
  defmacro sigil_z({:<<>>, _, [string]}, []) do
    ast = Code.string_to_quoted!(string)
    {ast, {:_zipper_meta, [if_undefined: :apply], Elixir}}
  end
end

