defmodule Recode.Task.SinglePipeTest do
  use RecodeCase

  alias Recode.Task.SinglePipe

  test "fix single pipe" do
    code = """
    x |> foo()
    """

    expected = """
    foo(x)
    """

    code
    |> run_task(SinglePipe, autocorrect: true)
    |> assert_code(expected)
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

    code
    |> run_task(SinglePipe, autocorrect: true)
    |> assert_code(expected)
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

    code
    |> run_task(SinglePipe, autocorrect: true)
    |> assert_code(expected)
  end

  test "does not expands single pipes that starts with a none zero fun" do
    """
    def fixme(arg) do
      foo(arg) |> zoo()
      foo(arg, :animal) |> zoo(:tiger)
      one(:a) |> two()
    end
    """
    |> run_task(SinglePipe, autocorrect: true)
    |> refute_update()
  end

  test "keeps pipes" do
    """
    def ok(arg) do
      arg
      |> bar()
      |> baz(:baz)
    end
    """
    |> run_task(SinglePipe, autocorrect: true)
    |> refute_update()
  end

  test "keeps pipes (length 3)" do
    """
    def ok(arg) do
      arg
      |> bar()
      |> baz(:baz)
      |> bing()
    end
    """
    |> run_task(SinglePipe, autocorrect: true)
    |> refute_update()
  end

  test "keeps pipes with tap" do
    """
    def ok(arg) do
      arg
      |> bar()
      |> tap(fn x -> IO.puts(x) end)
      |> baz(:baz)
    end
    """
    |> run_task(SinglePipe, autocorrect: true)
    |> refute_update()
  end

  test "keeps pipes with then" do
    """
    def ok(arg) do
      arg
      |> bar()
      |> then(fn x -> Enum.reverse(x) end)
    end
    """
    |> run_task(SinglePipe, autocorrect: true)
    |> refute_update()
  end

  test "reports single pipes violation" do
    """
    def fixme(arg) do
      arg |> zoo()
      arg |> zoo(:tiger)
    end
    """
    |> run_task(SinglePipe, autocorrect: false)
    |> assert_issues(2)
  end

  test "keeps |> when not used as pipe operator" do
    code = """
    defmodule Foo do
      defmacro a |> b do
        a |> Bar.foo()

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
        Bar.foo(a)

        fun = fn {x, pos}, acc ->
          Macro.pipe(acc, x, pos)
        end

        :lists.foldl(fun, left, Macro.unpipe(right))
      end

      defdelegate left |> right, to: Bar
    end
    """

    code
    |> run_task(SinglePipe, autocorrect: true)
    |> assert_code(expected)
  end
end
