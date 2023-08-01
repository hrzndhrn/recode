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

    test "fix simple unused variables in comments" do
      code = """
      def foo(bar) do
        # bar is not used
      end
      """

      expected = """
      def foo(_bar) do
        # bar is not used
      end
      """

      code
      |> run_task(UnusedVariable, autocorrect: true)
      |> assert_code(expected)
    end

    test "fix in fun call" do
      code = """
      def foo() do
        bar = String.to_atom()
        IO.inspect(bar)
      end
      """

      expected = """
      def foo() do
        bar = String.to_atom()
        IO.inspect(bar)
      end
      """

      code
      |> run_task(UnusedVariable, autocorrect: true)
      |> assert_code(expected)
    end

    test "fix in module" do
      code = """
      defmodule MyMod do
        require Logger

        defp download(items, dir) do
          Enum.map(items, fn item ->
            download(item, dir)
          end)
        end

        defp download(item, dir) do
          Logger.info("Downloading")
        end
      end
      """

      expected = """
      defmodule MyMod do
        require Logger

        defp download(items, dir) do
          Enum.map(items, fn item ->
            download(item, dir)
          end)
        end

        defp download(_item, _dir) do
          Logger.info("Downloading")
        end
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
