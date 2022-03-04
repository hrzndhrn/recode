defmodule Recode.Task.SinglePipeTest do
  use RecodeCase

  alias Recode.Task.SinglePipe

  describe "run/1" do
    test "fixes single pipes" do
      source = """
      def ok(arg) do
        arg
        |> bar()
        |> baz(:baz)
      end

      def fixme(arg) do
        arg |> zoo()
        arg |> zoo(:tiger)
      end
      """

      expected = """
      def ok(arg) do
        arg
        |> bar()
        |> baz(:baz)
      end

      def fixme(arg) do
        zoo(arg)
        zoo(arg, :tiger)
      end
      """

      [updated] = run_task_with_sources({SinglePipe, []}, [source])

      assert updated == expected
    end
  end
end
