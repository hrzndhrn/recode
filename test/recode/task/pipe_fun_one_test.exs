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

      assert_code source == expected
    end

    test "adds parenthes in single pipe" do
      code = """
      a |> IO.inspect
      """

      expected = """
      a |> IO.inspect()
      """

      source = run(code)

      assert_code source == expected
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

    test "reports issue for single pipe" do
      code = """
      def foo(arg) do
        arg |> IO.inspect
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

  test "keeps code when |> is not used as pipe operator" do
    code = """
    defmodule Foo do
      defmacro a |> b do
        a |> IO.inspect

        fun = fn {x, pos}, acc ->
          Macro.pipe(acc, x, pos)
        end

        :lists.foldl(fun, left, Macro.unpipe(right))
      end

      defdelegate left |> right, to: Bar
    end
    """

    expected = """
    defmodule Foo do
      defmacro a |> b do
        a |> IO.inspect()

        fun = fn {x, pos}, acc ->
          Macro.pipe(acc, x, pos)
        end

        :lists.foldl(fun, left, Macro.unpipe(right))
      end

      defdelegate left |> right, to: Bar
    end
    """

    source = run(code)

    assert_code source == expected
  end
end
