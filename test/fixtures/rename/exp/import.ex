defmodule Rename.Bar do
  def bar, do: :baz
end

defmodule Rename.Foo do
  import Rename.Bar

  def foo(:a), do: bar()

  def foo(:b) do
    bar()
  end
end
