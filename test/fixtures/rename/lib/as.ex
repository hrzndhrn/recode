defmodule Rename.Bar do
  def baz, do: :bar
end

defmodule Rename.Baz do
  def baz, do: :baz
end

defmodule Rename.Foo do
  alias Rename.Bar, as: Ace
  alias Rename.Baz, as: Asdf

  def foo(atom)

  def foo(:a), do: Ace.baz()

  def foo(:b) do
    {Ace.baz(), Asdf.baz()}
  end
end
