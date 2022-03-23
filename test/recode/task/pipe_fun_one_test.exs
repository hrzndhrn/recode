defmodule Recode.Task.PipeFunOneTest do
  use RecodeCase

  alias Recode.Task.PipeFunOne

  defp run(code, opts \\ [autocorrect: true]) do
    code |> source() |> run_task({PipeFunOne, opts})
  end

  describe "run/1" do
    test "adds parentheses" do
      code = """
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

      source = run(code)

      assert source.code == expected
    end

    test "reports issue" do
      code = """
      def foo(arg) do
        arg
        |> bar
        |> baz(:baz)
        |> zoo()
      end
      """

      source = run(code, autocorrect: false)

      assert_issue(source, PipeFunOne)
    end

    test "reports no issue" do
      code = """
      def foo(arg) do
        arg
        |> bar()
        |> baz(:baz)
        |> zoo()
      end
      """

      source = run(code, autocorrect: false)

      assert_no_issues(source)
    end
  end
end
