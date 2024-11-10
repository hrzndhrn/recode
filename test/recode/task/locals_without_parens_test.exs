defmodule Recode.Task.LocalsWithoutParensTest do
  use RecodeCase, async: false

  alias Recode.Task.LocalsWithoutParens
  alias Rewrite.DotFormatter

  test "remove parens" do
    dot_formatter =
      DotFormatter.from_formatter_opts(locals_without_parens: [foo: 1, bar: 2, baz: :*])

    code = """
    [x] = foo(bar(y))
    bar(y, x)
    baz(a)
    baz(a,b)
    baz(a,b,c)
    if(x == 1, do: true)
    """

    expected = """
    [x] = foo bar(y)
    bar y, x
    baz a
    baz a, b
    baz a, b, c
    if x == 1, do: true
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
end
