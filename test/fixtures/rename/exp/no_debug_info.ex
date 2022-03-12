defmodule Rename.Bar do
  def bar, do: :baz

  def bar(x), do: {x, :baz}
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
