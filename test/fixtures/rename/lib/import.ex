defmodule Rename.Bar do
  def baz, do: :baz
end

defmodule Rename.Foo do
  import Rename.Bar

  def foo(:a), do: baz()

  def foo(:b) do
    baz()
  end
end
