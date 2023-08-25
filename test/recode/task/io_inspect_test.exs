defmodule Recode.Task.IOInspectTest do
  use RecodeCase

  alias Recode.Task.IOInspect

  describe "run/1" do
    #
    # cases NOT changing code
    #

    test "keeps code" do
      """
      def foo(x) do
        {:ok, x}
      end
      """
      |> run_task(IOInspect, autocorrect: true)
      |> refute_update()
    end

    #
    # cases changing code
    #

    test "removes a IO.inspect call" do
      code = """
      def foo(x) do
        IO.inspect(x)
        IO.inspect(x, op: :po)
        {:ok, x}
      end
      """

      expected = """
      def foo(x) do
        {:ok, x}
      end
      """

      code
      |> run_task(IOInspect, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes piping into IO.inspect" do
      code = """
      def foo(x) do
        {:ok, x} |> IO.inspect()
      end
      """

      expected = """
      def foo(x) do
        {:ok, x}
      end
      """

      code
      |> run_task(IOInspect, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes piping into IO.inspect inside op" do
      code = """
      def foo(x, y) do
        x + y |> IO.inspect()
      end
      """

      expected = """
      def foo(x, y) do
        x + y
      end
      """

      code
      |> run_task(IOInspect, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes piping into IO.inspect at the end" do
      code = """
      def foo(x) do
        x
        |> alpha()
        |> bravo()
        |> IO.inspect()
      end
      """

      expected = """
      def foo(x) do
        x
        |> alpha()
        |> bravo()
      end
      """

      code
      |> run_task(IOInspect, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes piping into IO.inspect inside of a pipe" do
      code = """
      def foo(x) do
        x
        |> alpha()
        |> bravo()
        |> IO.inspect()
        |> charlie()
        |> delta()
      end
      """

      expected = """
      def foo(x) do
        x
        |> alpha()
        |> bravo()
        |> charlie()
        |> delta()
      end
      """

      code
      |> run_task(IOInspect, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes code when ref IO.inspect" do
      code = """
      def foo(x) do
        Enum.each(x, &IO.inspect/1)
        {:ok, x}
      end
      """

      expected = """
      def foo(x) do
        {:ok, x}
      end
      """

      code
      |> run_task(IOInspect, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes code when ref IO.inspect in pipe" do
      code = """
      def foo(x) do
        x
        |> bar()
        |> Enum.map(&IO.inspect/1)
        |> baz()
      end
      """

      expected = """
      def foo(x) do
        x
        |> bar()
        |> baz()
      end
      """

      code
      |> run_task(IOInspect, autocorrect: true)
      |> assert_code(expected)
    end

    #
    # cases NOT raising issues
    #

    test "does not trigger" do
      """
      def foo(x) do
        {:ok, x}
      end
      """
      |> run_task(IOInspect, autocorrect: false)
      |> refute_issues()
    end

    #
    # cases raising issues
    #

    test "reports issue for IO.inspect call" do
      """
      def foo(x) do
        IO.inspect(x)
        {:ok, x}
      end
      """
      |> run_task(IOInspect, autocorrect: false)
      |> assert_issue_with(reporter: IOInspect, line: 2)
    end

    test "reports issue when piping into IO.inspect" do
      """
      def foo(x) do
        {:ok, x} |> IO.inspect()
      end
      """
      |> run_task(IOInspect, autocorrect: false)
      |> assert_issue_with(reporter: IOInspect, line: 2)
    end

    test "reports issue when piping into IO.inspect at the end" do
      """
      def foo(x) do
        x
        |> Enum.reverse()
        |> bar()
        |> IO.inspect()
      end
      """
      |> run_task(IOInspect, autocorrect: false)
      |> assert_issue_with(reporter: IOInspect, line: 5)
    end

    test "reports issue when piping into IO.inspect inside of a pipe" do
      """
      def foo(x) do
        x
        |> Enum.reverse()
        |> IO.inspect()
        |> bar()
      end
      """
      |> run_task(IOInspect, autocorrect: false)
      |> assert_issue_with(reporter: IOInspect, line: 4, column: 6)
    end

    test "reports issue when ref IO.inspect" do
      """
      def foo(x) do
        Enum.each(x, &IO.inspect/1)
        {:ok, x}
      end
      """
      |> run_task(IOInspect, autocorrect: false)
      |> assert_issue_with(reporter: IOInspect, line: 2, column: 16)
    end

    test "reports issue when ref IO.inspect in pipe" do
      """
      def foo(x) do
        x
        |> bar()
        |> Enum.map(&IO.inspect/1)
        |> baz()
      end
      """
      |> run_task(IOInspect, autocorrect: false)
      |> assert_issue_with(reporter: IOInspect, line: 4)
    end
  end
end
