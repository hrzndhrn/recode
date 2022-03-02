defmodule Rename.Call do
  alias Rename.Bar
  alias Rename.Baz

  def foo(x) do
    Bar.baz(x)
    Bar.baz(x, 5)
    Rename.Bar.baz(x)
    _ignore = Bar.baz(x) + Rename.Bar.baz(x)
    Baz.baz()
    Baz.baz(x)
    Bar.foo(x)
  end
end
