defmodule Rename.Bar do
  def bar, do: :baz
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

  def foo(:a), do: Bar.bar()

  def foo(:b) do
    Bar.bar()
  end
end
