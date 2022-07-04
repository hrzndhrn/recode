defmodule Rename.Call do
  alias Rename.Bar
  alias Rename.Baz

  def foo(x) do
    Bar.bar(x)
    Bar.bar(x, 5)
    Rename.Bar.bar(x)
    _ignore = Bar.bar(x) + Rename.Bar.bar(x)
    Baz.baz()
    Baz.baz(x)
    Bar.foo(x)
  end
end
