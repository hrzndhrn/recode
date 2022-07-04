defmodule Rename.Bar do
  def bar, do: :bar
end

defmodule Rename.Baz do
  def baz, do: :baz
end

defmodule Rename.Foo do
  alias Rename.Bar, as: Ace
  alias Rename.Baz, as: Asdf

  def foo(atom)

  def foo(:a), do: Ace.bar()

  def foo(:b) do
    {Ace.bar(), Asdf.baz()}
  end
end
