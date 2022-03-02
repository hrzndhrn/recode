defmodule Traverse.Obelix do
  defmacro __using__(_opts) do
    quote do
    end
  end
end

defmodule Traverse.Pluto do
end

defmodule Traverse.Mouse do
  def micky(x), do: x + x
end

defmodule Traverse.Foo do
  use Traverse.Obelix, app: Traverse

  alias Traverse.Nested.Simple
  alias Donald.Duck, as: Goofy
  alias Foo.{Bar, Baz}

  import Traverse.Pluto
  import Traverse.Mouse, only: [micky: 1]

  require Logger

  def foo, do: Simple.foo()

  def xyz do
    Bar.x() + Baz.y() + Goofy.z()
  end

  def mouse do
    micky(:entenhausen)
  end
end
