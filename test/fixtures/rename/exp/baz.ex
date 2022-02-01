defmodule Rename.Baz do
  import Rename.Bar

  def foo(x) do
    bar(x)
  end
end
