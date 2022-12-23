defmodule Recode.Task.UnusedVariableTest do
  use RecodeCase

  alias Recode.Task.UnusedVariable

  defp run(code, opts \\ [autocorrect: true]) do
    code |> source() |> run_task({UnusedVariable, opts})
  end

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

      source = run(code)

      assert_code(source == expected)
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

      source = run(code)

      assert_code(source == expected)
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

      source = run(code)

      assert_code(source == expected)
    end

    test "reports an issue" do
      code = """
      def foo(bar) do
        baz = 1
        bar
      end
      """

      source = run(code, autocorrect: false)

      assert_issue(source, UnusedVariable)
    end
  end
end
