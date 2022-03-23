defmodule Recode.Task.TestFileExtTest do
  use RecodeCase

  alias Recode.Task.TestFileExt

  defp run(path, opts \\ [autocorrect: true]) do
    ":test" |> source(path) |> run_task({TestFileExt, opts})
  end

  test "updates path" do
    path = "test/foo_test.ex"
    source = run(path)

    assert source.path == path <> "s"
  end

  test "keeps path" do
    path = "test/foo_test.exs"
    source = run(path)

    assert source.path == path
  end

  test "reports issue" do
    path = "test/foo_test.ex"
    source = run(path, autocorrect: false)

    assert_issue(source, TestFileExt)
  end

  test "reports no issues" do
    path = "test/foo_test.exs"
    source = run(path, autocorrect: false)

    assert_no_issues(source)
  end
end
