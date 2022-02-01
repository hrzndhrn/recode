defmodule Rename.Baz do
  import Rename.Bar

  def foo(x) do
    baz(x)
  end
end
