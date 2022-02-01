defmodule Traverse.SomeModule do
  def add(a, b) do
    a + b
  end

  def call, do: :call
end

defmodule Traverse.Simple do
  alias Traverse.SomeModule
  import Traverse.Imp, only: [foo: 1, bar: 2]
  use Traverse.Asterix

  defmodule Nested do
    def bar(x) do
      x + 2
    end
  end

  def foo(x) do
    SomeModule.call()
    x * 2
  end
end

# a comment

defmodule Traverse.Foo do
  use Traverse.Obelix, app: Traverse

  alias Traverse.Nested.Simple
  alias Donald.Duck, as: Goofy
  alias Foo.{Bar, Baz}

  import Traverse.Pluto

  def foo, do: Simple.foo()
end
