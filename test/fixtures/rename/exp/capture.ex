defmodule Rename.Bar do
  def bar(x), do: {x, :baz}
end

defmodule Rename.Foo do
  import Rename.Bar

  def foo(list), do: Enum.map(list, &bar/1)
end

defmodule Rename.FooFoo do
  def foofoo(list), do: Enum.map(list, &Rename.Bar.bar/1)
end
