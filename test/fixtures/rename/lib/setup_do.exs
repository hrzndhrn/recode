defmodule Rename.Bar do
  def baz, do: :baz
  def baz(x), do: {:baz, x}
end

defmodule Rename.FooTest do
  use ExUnit.Case
  import Rename.Bar

  setup do
    baz()
    :ok
  end

  test "bar" do
    baz(5)
    assert baz(6)
  end
end

defmodule Rename.BarTest do
  use ExUnit.Case
  import Rename.Bar

  setup do
    x = 5
    baz(x)
    :ok
  end

  test "bar" do
    baz(5)
    assert baz(6)
  end
end
