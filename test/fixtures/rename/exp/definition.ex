defmodule Rename.Bar do
  def bar, do: :baz

  def bar(1), do: :baz

  def bar(2) do
    bar(1)
  end

  def bar(a, b) when b == 5 do
    bar(a, b, nil)
  end

  def bar(a, b) do
    bar(a, b, nil)
  end

  defp bar(a, b, c) do
    a + b == c
  end
end
