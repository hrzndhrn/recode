defmodule Recode.Task.RemoveParensTest do
  use RecodeCase, async: true

  alias Recode.Task.RemoveParens

  @moduletag :tmp_dir

  setup context do
    File.write("#{context.tmp_dir}/.formatter.exs", """
    [
      inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
      locals_without_parens: [foo: 1, bar: 2]
    ]
    """)

    {:ok, context}
  end

  test "remove parens", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      code = """
      x = foo(bar(y))
      bar(y, x)
      """

      expected = """
      x = foo bar(y)
      bar y, x
      """

      code
      |> run_task(RemoveParens, autocorrect: true)
      |> assert_code(expected)
    end)
  end

  test "removes parens" do
    code = """
    assert(true == false)
    """

    expected = """
    assert true == false
    """

    code
    |> run_task(RemoveParens, autocorrect: true)
    |> assert_code(expected)
  end

  test "respects arity" do
    code = """
    assert(true, "assert/2 is not in locals_without_parens")
    """

    expected = """
    assert(true, "assert/2 is not in locals_without_parens")
    """

    code
    |> run_task(RemoveParens, autocorrect: true)
    |> assert_code(expected)
  end

  test "adds issue" do
    """
    assert(true == false)
    """
    |> run_task(RemoveParens, autocorrect: false)
    |> assert_issue()
  end
end
