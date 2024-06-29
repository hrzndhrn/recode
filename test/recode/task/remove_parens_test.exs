defmodule Recode.Task.RemoveParensTest do
  use RecodeCase

  alias Recode.Task.RemoveParens

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
