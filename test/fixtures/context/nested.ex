defmodule Traverse.SomeModule do
  def add(a, b) do
    a + b
  end

  def call, do: :call
end

defmodule Traverse.Imp do
  def foo(a) do
    a + a
  end

  def bar(a, b) do
    a + b
  end
end

defmodule Traverse.Asterix do
  defmacro __using__(_opts) do
  end
end

# a comment

defmodule Traverse.Simple do
  alias Traverse.SomeModule
  import Traverse.Imp, only: [foo: 1, bar: 2]
  use Traverse.Asterix

  defmodule Nested do
    def bar(x) do
      foo(x) + bar(2, x)
    end
  end

  def foo(x) do
    SomeModule.call()
    x * 2
  end
end
