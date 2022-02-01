defmodule Rename.Bar do
  def baz, do: :baz
end

defmodule Rename.Foo do
  alias Rename.Bar, as: Ace

  def foo(:a), do: Ace.baz()

  def foo(:b) do
    Ace.baz()
  end
end
