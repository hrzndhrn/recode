defmodule Recode.Task.SinglePipeTest do
  use RecodeCase

  alias Recode.Task.SinglePipe

  defp run(code, opts \\ [autocorrect: true]) do
    code |> source() |> run_task({SinglePipe, opts})
  end

  test "fix single pipe" do
    code = "x |> foo()"
    expected = "foo(x)"

    source = run(code)

    assert_code source == expected
  end

  test "fixes single pipes" do
    code = """
    def fixme(arg) do
      arg |> zoo()
      arg |> zoo(:tiger)
      one() |> two()
      one() |> two(:b)
      "" |> String.split()
      "go go" |> String.split()
      1 |> to_string()
      :anton |> Foo.bar()
      [1, 2, 3] |> Enum.map(fn x -> x * x end)
      %{a: 1, b: 2} |> Enum.map(fn {k, v} -> {k, v + 1} end)
    end
    """

    expected = """
    def fixme(arg) do
      zoo(arg)
      zoo(arg, :tiger)
      two(one())
      two(one(), :b)
      String.split("")
      String.split("go go")
      to_string(1)
      Foo.bar(:anton)
      Enum.map([1, 2, 3], fn x -> x * x end)
      Enum.map(%{a: 1, b: 2}, fn {k, v} -> {k, v + 1} end)
    end
    """

    source = run(code)

    assert_code source == expected
  end

  test "fixes single pipes with heredoc" do
    code = """
    def hello do
      \"\"\"
      world
      \"\"\"
      |> String.split()

      \"\"\"
      bar
      \"\"\"
      |> foo("baz")

    end
    """

    expected = """
    def hello do
      String.split(\"\"\"
      world
      \"\"\")

      foo(
        \"\"\"
        bar
        \"\"\",
        "baz"
      )
    end
    """

    source = run(code)

    assert_code source == expected
  end

  test "does not expands single pipes that starts with a none zero fun" do
    code = """
    def fixme(arg) do
      foo(arg) |> zoo()
      foo(arg, :animal) |> zoo(:tiger)
      one(:a) |> two()
    end
    """

    source = run(code)

    assert_code source == code
  end

  test "keeps pipes" do
    code = """
    def ok(arg) do
      arg
      |> bar()
      |> baz(:baz)
    end
    """

    source = run(code)

    assert_code source == code
  end

  test "keeps pipes (length 3)" do
    code = """
    def ok(arg) do
      arg
      |> bar()
      |> baz(:baz)
      |> bing()
    end
    """

    source = run(code)

    assert_code source == code
  end

  test "keeps pipes with tap" do
    code = """
    def ok(arg) do
      arg
      |> bar()
      |> tap(fn x -> IO.puts(x) end)
      |> baz(:baz)
    end
    """

    source = run(code)

    assert_code source == code
  end

  test "keeps pipes with then" do
    code = """
    def ok(arg) do
      arg
      |> bar()
      |> then(fn x -> Enum.reverse(x) end)
    end
    """

    source = run(code)

    assert_code source == code
  end

  test "reports single pipes violation" do
    code = """
    def fixme(arg) do
      arg |> zoo()
      arg |> zoo(:tiger)
    end
    """

    source = run(code, autocorrect: false)

    assert_issues(source, SinglePipe, 2)
  end

  test "keeps |> when not used as pipe operator" do
    code = """
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

    expected = """
    defmodule Foo do
      defmacro a |> b do
        IO.inspect(a)

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
