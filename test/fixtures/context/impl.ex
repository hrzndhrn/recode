defmodule Traverse.Foo do
  use Traverse.Something

  @impl true
  def foo(x), do: {:foo, x}

  @impl Traverse.Something
  def baz, do: :baz
end
