defmodule Rename.Bar do
  def bar, do: :baz
end

defmodule Rename.Foo do
  alias Rename.Bar, as: Ace

  def foo(:a), do: Ace.bar()

  def foo(:b) do
    Ace.bar()
  end
end
