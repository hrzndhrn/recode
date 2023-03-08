# Modules is changed to another names
defmodule Rename.Bar do
  def baz, do: :bar
end

defmodule Rename.Baz do
  def baz, do: :baz

  def baz(1), do: :baz_1
end

defmodule Rename.BarBaz do
  def baz(1, 2, 3), do: :bar_baz
end

defmodule Rename.Foo do
  alias Rename.Bar, as: Ace
  alias Rename.Baz, as: Asdf

  def foo(atom)

  def foo(:a), do: Ace.baz()

  def foo(:b) do
    {Ace.baz(), Asdf.baz(), Rename.BarBaz.baz(1, 2, 3)}
  end

  def foofoo(b) do
    Asdf.baz(b)
  end
end
