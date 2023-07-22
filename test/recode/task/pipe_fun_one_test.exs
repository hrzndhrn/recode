defmodule Recode.Task.PipeFunOneTest do
  use RecodeCase

  alias Recode.Task.PipeFunOne

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

      code
      |> run_task(PipeFunOne, autocorrect: true)
      |> assert_code(expected)
    end

    test "adds parenthes in single pipe" do
      code = """
      a |> IO.inspect
      """

      expected = """
      a |> IO.inspect()
      """

      code
      |> run_task(PipeFunOne, autocorrect: true)
      |> assert_code(expected)
    end

    test "reports issue" do
      """
      def foo(arg) do
        arg
        |> bar
        |> baz(:baz)
        |> zoo()
      end
      """
      |> run_task(PipeFunOne, autocorrect: false)
      |> assert_issue_with(reporter: PipeFunOne)
    end

    test "reports issue for single pipe" do
      """
      def foo(arg) do
        arg |> IO.inspect
      end
      """
      |> run_task(PipeFunOne, autocorrect: false)
      |> assert_issue()
    end

    test "reports no issue" do
      """
      def foo(arg) do
        arg
        |> bar()
        |> baz(:baz)
        |> zoo()
      end
      """
      |> run_task(PipeFunOne, autocorrect: false)
      |> refute_issues()
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

    code
    |> run_task(PipeFunOne, autocorrect: true)
    |> assert_code(expected)
  end
end
