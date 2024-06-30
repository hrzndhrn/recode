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

  test "adds issue", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      """
      x = foo(bar)
      """
      |> run_task(RemoveParens, autocorrect: false)
      |> assert_issue()
    end)
  end
end
