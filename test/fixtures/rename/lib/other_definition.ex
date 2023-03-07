defmodule Rename.Bar do
  def baz(x), do: {:baz, x}
end

defmodule Rename.Foo do
  @moduledoc """
  There are multiple definitions of baz/1 in this module.
  one is from the alias, the others are from the module itself.
  """
  alias Rename.Bar

  def baz, do: :baz

  def baz(1), do: :baz

  def baz(2) do
    baz(1)
  end

  def baz(x) do
    Bar.baz(x)
  end

  def baz(a, b) when b == 5 do
    baz(a, b, nil)
  end

  def baz(a, b) do
    baz(a, b, nil)
  end

  defp baz(a, b, c) do
    a + b == c
  end
end
