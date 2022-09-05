defmodule Rename.Bar do
  def baz(x), do: {:baz, x}
end

defmodule Rename.Foo do
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
