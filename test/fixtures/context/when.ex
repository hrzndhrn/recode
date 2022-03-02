defmodule Context.When do
  def foo(x) when x == 5 do
    x * 2
  end

  def baz(x) when x == 5, do: :baz
end
