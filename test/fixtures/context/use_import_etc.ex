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
  import Traverse.{Gladstone, Gander}

  require Logger
  require Traverse.Pluto, as: Animal

  def foo, do: Simple.foo()

  def xyz do
    Bar.x() + Baz.y() + Goofy.z()
  end

  def mouse do
    micky(:entenhausen)
  end
end

defmodule Traverse.Timer do
  import :timer
end

defmodule Traverse.RequireAlias do
  require alias Traverse.Pluto
end

defmodule Traverse.RequireAliasAs do
  require alias Traverse.Pluto, as: Foo
end

defmodule Traverse.AliasRequire do
  alias require Traverse.Pluto
end
