defmodule Rename.Bar do
  def bar, do: :baz

  def bar(x), do: {x, :baz}
end

defmodule Rename.Foo do
  import Rename.Bar

  def foo(:a), do: bar()

  def foo(:b) do
    bar() |> bar() |> List.wrap()
  end

  def go(x) do
    x
  end
end

defmodule Rename.FooFoo do
  import Rename.Bar, only: [bar: 0, bar: 1]

  def foofoo do
    bar() |> bar() |> List.wrap()
  end
end
