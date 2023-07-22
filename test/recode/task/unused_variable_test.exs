defmodule Recode.Task.UnusedVariableTest do
  use RecodeCase

  alias Recode.Task.UnusedVariable

  describe "run/1" do
    test "fix simple unused variables" do
      code = """
      def foo(bar) do
        baz = 1
        bar
      end
      """

      expected = """
      def foo(bar) do
        _baz = 1
        bar
      end
      """

      code
      |> run_task(UnusedVariable, autocorrect: true)
      |> assert_code(expected)
    end

    test "fix multiple unused variables" do
      code = """
      def foo(bar) do
        baz = other_var = 1
        hello = 1
        bar
      end
      """

      expected = """
      def foo(bar) do
        _baz = _other_var = 1
        _hello = 1
        bar
      end
      """

      code
      |> run_task(UnusedVariable, autocorrect: true)
      |> assert_code(expected)
    end

    test "fix unused variables in anonymous function" do
      code = """
      fn bar ->
        foo = 1
        bar
      end
      """

      expected = """
      fn bar ->
        _foo = 1
        bar
      end
      """

      code
      |> run_task(UnusedVariable, autocorrect: true)
      |> assert_code(expected)
    end

    test "reports an issue" do
      """
      def foo(bar) do
        baz = 1
        bar
      end
      """
      |> run_task(UnusedVariable, autocorrect: false)
      |> assert_issue()
    end
  end
end
