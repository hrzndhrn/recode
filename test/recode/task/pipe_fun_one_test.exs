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
      end
      """

      [updated] = run_task_with_sources({PipeFunOne, []}, [source])

      assert updated == expected
    end
  end
end
