defmodule Rename.Bar do
  def baz, do: :baz
end

defmodule Rename.Baz do
  defmacro __using__(_opts) do
    quote do
      alias Rename.Bar
    end
  end
end

defmodule Rename.Foo do
  use Rename.Baz

  def foo(:a), do: Bar.baz()

  def foo(:b) do
    Bar.baz()
  end
end
