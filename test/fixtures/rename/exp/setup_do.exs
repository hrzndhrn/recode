defmodule Rename.Bar do
  def bar, do: :baz
  def bar(x), do: {:baz, x}
end

defmodule Rename.FooTest do
  use ExUnit.Case
  import Rename.Bar

  setup do
    bar()
  end

  test "bar" do
    bar(5)
    assert bar(6)
  end
end

defmodule Rename.BarTest do
  use ExUnit.Case
  import Rename.Bar

  setup do
    x = 5
    bar(x)
  end

  test "bar" do
    bar(5)
    assert bar(6)
  end
end
