defmodule Rename.Call do
  alias Rename.Bar

  def foo(x) do
    Bar.baz(x)
    Bar.baz(x, 5)
    Rename.Bar.baz(x)
    Bar.baz(x) + Rename.Bar.baz(x)
  end
end
