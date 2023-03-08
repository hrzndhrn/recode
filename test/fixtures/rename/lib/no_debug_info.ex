defmodule Rename.Bar do
  def baz, do: :baz

  def baz(x), do: {x, :baz}
end

defmodule Rename.Foo do
  import Rename.Bar

  def foo(:a), do: baz()

  def foo(:b) do
    bar() |> baz() |> List.wrap()
  end

  def go(x) do
    x
  end
end
