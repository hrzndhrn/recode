defmodule Recode.Task.DbgTest do
  use RecodeCase

  alias Recode.Task.Dbg

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
      |> run_task(Dbg, autocorrect: true)
      |> refute_update()
    end

    test "keeps code when assigning dbg" do
      """
      def foo(x) do
        dbg = bar(x)
        dbg = dbg * 2
        {:ok, x}
      end
      """
      |> run_task(Dbg, autocorrect: true)
      |> refute_update()
    end

    #
    # cases changing code
    #

    test "removes a dbg call" do
      code = """
      def foo(x) do
        dbg(x)
        dbg(x, op: :po)
        {:ok, x}
      end
      """

      expected = """
      def foo(x) do
        {:ok, x}
      end
      """

      code
      |> run_task(Dbg, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes a Kernel.dbg call" do
      code = """
      def foo(x) do
        Kernel.dbg(x, op: :po)
        {:ok, x}
      end
      """

      expected = """
      def foo(x) do
        {:ok, x}
      end
      """

      code
      |> run_task(Dbg, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes piping into dbg" do
      code = """
      def foo(x) do
        {:ok, x} |> dbg()
      end
      """

      expected = """
      def foo(x) do
        {:ok, x}
      end
      """

      code
      |> run_task(Dbg, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes piping into Kernel.dbg" do
      code = """
      def foo(x) do
        {:ok, x} |> Kernel.dbg()
      end
      """

      expected = """
      def foo(x) do
        {:ok, x}
      end
      """

      code
      |> run_task(Dbg, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes piping into dbg inside op" do
      code = """
      def foo(x, y) do
        x + y |> dbg()
      end
      """

      expected = """
      def foo(x, y) do
        x + y
      end
      """

      code
      |> run_task(Dbg, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes piping into dbg at the end" do
      code = """
      def foo(x) do
        x
        |> alpha()
        |> bravo()
        |> dbg()
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
      |> run_task(Dbg, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes piping into dbg inside of a pipe" do
      code = """
      def foo(x) do
        x
        |> alpha()
        |> bravo()
        |> dbg()
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
      |> run_task(Dbg, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes code when ref dbg" do
      code = """
      def foo(x) do
        Enum.each(x, &dbg/1)
        {:ok, x}
      end
      """

      expected = """
      def foo(x) do
        {:ok, x}
      end
      """

      code
      |> run_task(Dbg, autocorrect: true)
      |> assert_code(expected)
    end

    test "removes code when ref dbg in pipe" do
      code = """
      def foo(x) do
        x
        |> bar()
        |> Enum.map(&dbg/1)
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
      |> run_task(Dbg, autocorrect: true)
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
      |> run_task(Dbg, autocorrect: false)
      |> refute_issues()
    end

    #
    # cases raising issues
    #

    test "reports issue for dbg call" do
      """
      def foo(x) do
        dbg(x)
        {:ok, x}
      end
      """
      |> run_task(Dbg, autocorrect: false)
      |> assert_issue_with(reporter: Dbg, line: 2)
    end

    test "reports issue for Kernel.dbg call" do
      """
      def foo(x) do
        Kernel.dbg(x)
        {:ok, x}
      end
      """
      |> run_task(Dbg, autocorrect: false)
      |> assert_issue_with(reporter: Dbg, line: 2)
    end

    test "reports issue when piping into dbg" do
      """
      def foo(x) do
        {:ok, x} |> dbg()
      end
      """
      |> run_task(Dbg, autocorrect: false)
      |> assert_issue_with(reporter: Dbg, line: 2)
    end

    test "reports issue when piping into Kernel.dbg" do
      """
      def foo(x) do
        {:ok, x} |> Kernel.dbg()
      end
      """
      |> run_task(Dbg, autocorrect: false)
      |> assert_issue_with(reporter: Dbg, line: 2)
    end

    test "reports issue when piping into dbg at the end" do
      """
      def foo(x) do
        x
        |> Enum.reverse()
        |> bar()
        |> dbg()
      end
      """
      |> run_task(Dbg, autocorrect: false)
      |> assert_issue_with(reporter: Dbg, line: 5)
    end

    test "reports issue when piping into dbg inside of a pipe" do
      """
      def foo(x) do
        x
        |> Enum.reverse()
        |> dbg()
        |> bar()
      end
      """
      |> run_task(Dbg, autocorrect: false)
      |> assert_issue_with(reporter: Dbg, line: 4)
    end

    test "reports issue when ref dbg" do
      """
      def foo(x) do
        Enum.each(x, &dbg/1)
        {:ok, x}
      end
      """
      |> run_task(Dbg, autocorrect: false)
      |> assert_issue_with(reporter: Dbg, line: 2)
    end

    test "reports issue when ref dbg in pipe" do
      """
      def foo(x) do
        x
        |> bar()
        |> Enum.map(&dbg/1)
        |> baz()
      end
      """
      |> run_task(Dbg, autocorrect: false)
      |> assert_issue_with(reporter: Dbg, line: 4)
    end
  end
end
