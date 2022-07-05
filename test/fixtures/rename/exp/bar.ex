defmodule Rename.Bar do
  @moduledoc false

  @doc """
  Bla `bar/1` bla
  """
  @spec bar(integer()) :: integer
  def bar(z) do
    z + 10
  end

  def zoo(a) do
    bar(a)
  end
end
