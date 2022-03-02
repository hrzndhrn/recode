defmodule Recode.Task.PipeFunOneTest do
  use RecodeCase

  alias Recode.Task.PipeFunOne

  describe "run/1" do
    test "expands aliases" do
      source = """
      def foo(arg) do
        arg
        |> bar
        |> baz(:baz)
        |> zoo()
      end
      """

      expected = """
      def foo(arg) do
        arg
        |> bar()
        |> baz(:baz)
        |> zoo()
      end\
      """

      # assert run_task(PipeFunOne, source) == expected
      refute "TODO"
    end
  end
end
