defmodule Recode.Task.FilterCountTest do
  use RecodeCase

  alias Recode.Task.FilterCount

  defp run(code, opts \\ [autocorrect: true]) do
    code |> source() |> run_task({FilterCount, opts})
  end

  describe "run/1" do
    #
    # cases NOT changing code
    #

    test "keeps correct Enum.count" do
      code = """
      def foo(x) do
        {
          Enum.count(x),
          Enum.count(x, fn y -> rem(y, 2) == 0 end),
          x |> Enum.reverse(x) |> Enum.count(fn y -> rem(y, 2) == 0 end)
        }
      end
      """

      source = run(code)

      assert source.content == code
    end

    test "keeps code when piping into Enum.count/2" do
      code = """
      def foo(x) do
        x |> Enum.filter(fn x -> rem(x, 2) == 0 end) |> Enum.count(fn x -> rem(x, 3) == 0 end)
      end
      """

      source = run(code)

      assert source.content == code
    end

    test "keeps code for Enum.count/2" do
      code = """
      def foo(x) do
        Enum.count(Enum.filter(x, fn x -> rem(x, 2) == 0 end), fn x -> rem(x, 3) == 0 end)
      end
      """

      source = run(code)

      assert source.content == code
    end

    #
    # cases changing code
    #

    test "corrects code when piping Enum.filter into Enum.count/1" do
      code = """
      def foo(arg) do
        Enum.filter(arg, fn x -> rem(x, 2) == 0 end)
        |> Enum.count()
      end
      """

      expected = """
      def foo(arg) do
        Enum.count(arg, fn x -> rem(x, 2) == 0 end)
      end
      """

      source = run(code)

      assert_code(source, expected)
    end

    test "corrects code when piping arg |> Enum.filter into Enum.count/1" do
      code = """
      def foo(arg) do
        arg
        |> Enum.filter(fn x -> rem(x, 2) == 0 end)
        |> Enum.count()
      end
      """

      expected = """
      def foo(arg) do
        Enum.count(arg, fn x -> rem(x, 2) == 0 end)
      end
      """

      source = run(code)

      assert_code(source, expected)
    end

    test "corrects code when piping Enum.filter into Enum.count/1 at the end of a pipeline" do
      code = """
      def foo(arg) do
        arg
        |> foo()
        |> Enum.filter(fn x -> rem(x, 2) == 0 end)
        |> Enum.count()
      end
      """

      expected = """
      def foo(arg) do
        arg
        |> foo()
        |> Enum.count(fn x -> rem(x, 2) == 0 end)
      end
      """

      source = run(code)

      assert_code(source, expected)
    end

    test "corrects code when piping Enum.filter into Enum.count/1 at the start of a pipeline" do
      code = """
      def foo(arg) do
        arg
        |> Enum.filter(fn x -> rem(x, 2) == 0 end)
        |> Enum.count()
        |> foo()
      end
      """

      expected = """
      def foo(arg) do
        arg
        |> Enum.count(fn x -> rem(x, 2) == 0 end)
        |> foo()
      end
      """

      source = run(code)

      assert_code(source, expected)
    end

    test "corrects code when piping Enum.filter into Enum.count/1 inside a pipeline" do
      code = """
      def foo(arg) do
        arg
        |> foo()
        |> Enum.filter(fn x -> rem(x, 2) == 0 end)
        |> Enum.count()
        |> Enum.reverse()
      end
      """

      expected = """
      def foo(arg) do
        arg
        |> foo()
        |> Enum.count(fn x -> rem(x, 2) == 0 end)
        |> Enum.reverse()
      end
      """

      source = run(code)

      assert_code(source, expected)
    end

    test "corrects code when Enum.count gets Enum.filter pipe as argument" do
      code = """
      def foo(arg) do
        Enum.count(arg |> Enum.filter(fn x -> rem(x, 2) == 0 end))
      end
      """

      expected = """
      def foo(arg) do
        Enum.count(arg, fn x -> rem(x, 2) == 0 end)
      end
      """

      source = run(code)

      assert_code(source, expected)
    end

    test "corrects code when Enum.count gets Enum.filter as argument" do
      code = """
      def foo(arg) do
        Enum.count(Enum.filter(arg, fn x -> rem(x, 2) == 0 end))
      end
      """

      expected = """
      def foo(arg) do
        Enum.count(arg, fn x -> rem(x, 2) == 0 end)
      end
      """

      source = run(code)

      assert_code(source, expected)
    end

    test "corrects code when Enum.count gets a pipline ending with Enum.filter as argument" do
      code = """
      def foo(arg) do
        Enum.count(arg |> Enum.reverse() |> Enum.filter(fn x -> rem(x, 2) == 0 end))
      end
      """

      expected = """
      def foo(arg) do
        arg |> Enum.reverse() |> Enum.count(fn x -> rem(x, 2) == 0 end)
      end
      """

      source = run(code)

      assert_code(source, expected)
    end

    #
    # cases NOT raising issues
    #

    test "reports no issue 1" do
      code = """
      def foo(arg) do
        Enum.count(arg, fn x -> rem(x, 2) == 0 end)
      end
      """

      source = run(code, autocorrect: false)

      refute_issues(source)
    end

    #
    # cases raising issues
    #

    test "reports issue 1" do
      code = """
      def foo(arg) do
        arg
        |> Enum.filter(fn x -> rem(x, 2) == 0 end)
        |> Enum.count()
      end
      """

      source = run(code, autocorrect: false)

      assert_issue(source, FilterCount)
    end

    test "reports issue 2" do
      code = """
      def foo(arg) do
        arg
        |> foo()
        |> Enum.filter(fn x -> rem(x, 2) == 0 end)
        |> Enum.count()
      end
      """

      source = run(code, autocorrect: false)

      assert_issue(source, FilterCount)
    end

    test "reports issue 3" do
      code = """
      def foo(arg) do
        Enum.count(Enum.filter(arg, fn x -> rem(x, 2) == 0 end))
      end
      """

      source = run(code, autocorrect: false)

      assert_issue(source, FilterCount)
    end
  end
end
