defmodule Rename.Bar do
  def baz, do: :baz
  def baz(x), do: {:baz, x}
end

defmodule Rename.FooTest do
  use ExUnit.Case
  import Rename.Bar

  setup do
    baz()
  end
end

defmodule Rename.BarTest do
  use ExUnit.Case
  import Rename.Bar

  setup do
    x = 5
    baz(x)
  end
end
