defmodule Rename.Bar do
  @moduledoc false

  @doc """
  Bla `baz/1` bla
  """
  @spec baz(integer()) :: integer
  def baz(z) do
    z + 10
  end

  def zoo(a) do
    baz(a)
  end
end
