defmodule Rename.Bar do
  def baz, do: :baz

  def baz(x), do: {x, :baz}
end

defmodule Rename.Foo do
  import Rename.Bar

  def foo(:a), do: baz()

  def foo(:b) do
    baz() |> baz() |> List.wrap()
  end

  def go(x) do
    x
  end
end

defmodule Rename.FooFoo do
  import Rename.Bar, only: [baz: 0, baz: 1]

  def foofoo do
    baz() |> baz() |> List.wrap()
  end
end
