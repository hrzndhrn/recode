defmodule Rename.Call do
  alias Rename.Bar

  def foo(x) do
    Bar.bar(x)
    Bar.bar(x, 5)
    Rename.Bar.bar(x)
    Bar.bar(x) + Rename.Bar.bar(x)
  end
end
