defmodule Rename.Bar do
  def baz, do: :baz

  def baz(1), do: :baz

  def baz(2) do
    baz(1)
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
