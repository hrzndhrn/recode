defmodule Recode.Task.LocalsWithoutParensTest do
  use RecodeCase, async: false

  alias Recode.Task.LocalsWithoutParens
  alias Rewrite.DotFormatter

  test "remove parens" do
    dot_formatter =
      DotFormatter.from_formatter_opts(locals_without_parens: [foo: 1, bar: 2, baz: :*])

    # code = """
    # [x] = foo(bar(y))
    # bar(y, x)
    # baz(a)
    # baz(a,b)
    # baz(a,b,c)
    # if(x == 1, do: true)
    # """

    code = """
    [x] = foo(bar(y))
    """

    expected = """
    [x] = foo bar(y)
    """

    code
    |> run_task(LocalsWithoutParens, autocorrect: true, dot_formatter: dot_formatter)
    |> assert_code(expected)
  end

  test "does not remove parens in def*" do
    dot_formatter =
      DotFormatter.from_formatter_opts(locals_without_parens: [foo: 1, bar: 2, baz: :*])

    code = """
    def foo(x) do
      bar(x, 2)
    end

    defp bar(_x, y) do
      foo(y)
    end
    """

    expected = """
    def foo(x) do
      bar x, 2
    end

    defp bar(_x, y) do
      foo y
    end
    """

    code
    |> run_task(LocalsWithoutParens, autocorrect: true, dot_formatter: dot_formatter)
    |> assert_code(expected)
  end

  test "adds issue" do
    dot_formatter = DotFormatter.from_formatter_opts(locals_without_parens: [foo: 1])

    """
    x = foo(bar)
    """
    |> run_task(LocalsWithoutParens, autocorrect: false, dot_formatter: dot_formatter)
    |> assert_issue()
  end

  test "adds no issue" do
    dot_formatter = DotFormatter.from_formatter_opts(locals_without_parens: [foo: 1])

    """
    x = foo bar
    """
    |> run_task(LocalsWithoutParens, autocorrect: false, dot_formatter: dot_formatter)
    |> refute_issues()
  end

  test "adds no issue for def" do
    """
    def hello do
      :world
    end
    """
    |> run_task(LocalsWithoutParens, autocorrect: false)
    |> refute_issues()
  end

  test "add no issue for parens in do:" do
    dot_formatter = DotFormatter.from_formatter_opts(locals_without_parens: [foo: 1])

    """
    def bar(x) when is_binary(x), do: foo(x)
    """
    |> run_task(LocalsWithoutParens, autocorrect: false, dot_formatter: dot_formatter)
    |> refute_issues()
  end

  test "add no issue for parens in tuples and maps" do
    dot_formatter = DotFormatter.from_formatter_opts(locals_without_parens: [foo: 1])

    """
    {a, foo(b)}
    {a, foo(b), c}
    %{a: foo b}
    """
    |> run_task(LocalsWithoutParens, autocorrect: false, dot_formatter: dot_formatter)
    |> refute_issues()
  end

  test "add no issue for multiline calls" do
    dot_formatter = DotFormatter.from_formatter_opts(locals_without_parens: [foo: 2])

    """
    foo(x, y)
    foo(
      x,
      y
    )
    """
    |> run_task(LocalsWithoutParens, autocorrect: false, dot_formatter: dot_formatter)
    |> assert_issues(1)
  end

  test "add no issue for calls in pipe" do
    dot_formatter = DotFormatter.from_formatter_opts(locals_without_parens: [foo: 2])

    """
    x |> foo(y, z)
    """
    |> run_task(LocalsWithoutParens, autocorrect: false, dot_formatter: dot_formatter)
    |> refute_issues()
  end
end
