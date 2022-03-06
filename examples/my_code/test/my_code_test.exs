defmodule MyCodeTest do
  use ExUnit.Case
  doctest MyCode

  test "greets the world" do
    assert MyCode.hello() == :world
  end
end
