defmodule Recode.Utils do
  @moduledoc """
  This module provides utility functions for `recode`.
  """

  @doc """
  Returns `true` id `value` ends with `suffix`.

  Both, value and suffix must be lists or module aliases.

  ## Examples

      iex> Recode.Utils.ends_with?(Foo.Bar, Bar)
      true
      iex> Recode.Utils.ends_with?(Foo, Foo.Bar)
      false
      iex> Recode.Utils.ends_with?(Foo.Bar, Baz)
      false

      iex> Recode.Utils.ends_with?([1, 2, 3], [2, 3])
      true
      iex> Recode.Utils.ends_with?([1, 2, 3], [2, 9])
      false
  """
  @spec ends_with?(value :: list() | module(), suffix :: list() | module()) :: boolean
  def ends_with?(value, suffix) when is_atom(value) and is_atom(suffix) do
    list = Module.split(value)
    suffix = Module.split(suffix)

    ends_with?(list, suffix)
  end

  def ends_with?(list, suffix) when is_list(list) and is_list(suffix) do
    case length(list) - length(suffix) do
      diff when diff < 0 -> false
      diff -> Enum.drop(list, diff) == suffix
    end
  end
end
