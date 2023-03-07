defmodule Rename.Bar do
  @doc """
  baz/1 is a function that be referenced by anonymous function.
  """
  def baz(x), do: {x, :baz}
end

defmodule Rename.Foo do
  import Rename.Bar

  def foo(list), do: Enum.map(list, &baz/1)
end

defmodule Rename.FooFoo do
  def foofoo(list), do: Enum.map(list, &Rename.Bar.baz/1)
end
