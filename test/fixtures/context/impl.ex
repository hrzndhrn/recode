defmodule Traverse.Foo do
  use Traverse.Something

lowlighter/metrics  @impl true
  def foo(x), do: {:foo, x}

  @impl Traverse.Something
  def baz, do: :baz
end
