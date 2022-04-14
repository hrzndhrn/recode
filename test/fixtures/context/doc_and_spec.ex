defmodule Traverse.Simple do
  @moduledoc """
  Doc for module simple
  """
end

defmodule Traverse.Simpler do
  @doc """
  Doc for foo
  """

  @ignore "me"

  @spec foo(integer() | nil) :: integer() | nil
  def foo(nil), do: nil

  def foo(x) do
    x * 2
  end

  def baz, do: :baz
end
