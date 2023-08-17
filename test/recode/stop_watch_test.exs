defmodule Recode.StopWatchTest do
  use ExUnit.Case

  alias Recode.StopWatch

  doctest Recode.StopWatch

  describe "init/1" do
    test "raises an ArgumentError when already initalized" do
      message = """
      errors were found at the given arguments:

        * 1st argument: table name already exists
      """

      assert_raise(ArgumentError, message, fn ->
        StopWatch.init!(:foo)
        StopWatch.init!(:foo)
      end)
    end
  end
end
