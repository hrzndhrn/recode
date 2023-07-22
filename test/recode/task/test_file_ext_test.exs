defmodule Recode.Task.TestFileExtTest do
  use RecodeCase

  alias Recode.Task.TestFileExt

  test "updates path" do
    path = "test/foo_test.ex"

    ":test"
    |> source(path)
    |> run_task(TestFileExt, autocorrect: true)
    |> assert_path(path <> "s")
  end

  test "keeps path" do
    path = "test/foo_test.exs"

    ":test"
    |> source(path)
    |> run_task(TestFileExt, autocorrect: true)
    |> refute_update()
  end

  test "reports issue" do
    path = "test/foo_test.ex"

    ":test"
    |> source(path)
    |> run_task(TestFileExt, autocorrect: false)
    |> assert_issue_with(reporter: TestFileExt)
  end

  test "reports no issues" do
    path = "test/foo_test.exs"

    ":test"
    |> source(path)
    |> run_task(TestFileExt, autocorrect: false)
    |> refute_issues()
  end
end
