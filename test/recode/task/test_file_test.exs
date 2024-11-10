defmodule Recode.Task.TestFileTest do
  use RecodeCase

  alias Recode.Task.TestFile

  test "updates file extension" do
    path = "test/foo_test.ex"

    ":test"
    |> source(path)
    |> run_task(TestFile, autocorrect: true)
    |> assert_path(path <> "s")
  end

  test "updates path" do
    path = "test/foo_test.ex"

    """
    defmodule FooTest do
    end
    """
    |> source(path)
    |> run_task(TestFile, autocorrect: true)
    |> assert_path(path <> "s")
  end

  test "updates path for missing _test with extension .ex" do
    path = "test/foo.ex"

    """
    defmodule FooTest do
    end
    """
    |> source(path)
    |> run_task(TestFile, autocorrect: true)
    |> assert_path("test/foo_test.exs")
  end

  test "keeps path" do
    path = "test/foo_test.exs"

    ":test"
    |> source(path)
    |> run_task(TestFile, autocorrect: true)
    |> refute_update()
  end

  test "keeps path when no test module was found" do
    path = "test/support/foo.ex"

    """
    defmodule Foo do
      @moduledoc "A helper"
    end
    """
    |> source(path)
    |> run_task(TestFile, autocorrect: true)
    |> refute_update()
  end

  test "reports issue" do
    path = "test/foo_test.ex"

    ":test"
    |> source(path)
    |> run_task(TestFile, autocorrect: false)
    |> assert_issue_with(reporter: TestFile)
  end

  test "reports issue when _test is missing" do
    path = "test/foo.exs"

    """
    defmodule FooTest do
    end
    """
    |> source(path)
    |> run_task(TestFile, autocorrect: false)
    |> assert_issue_with(reporter: TestFile)
  end

  test "reports issue when _test is missing and multiple test modules exist" do
    path = "test/foo.exs"

    """
    defmodule BarTest do
    end

    defmodule BazTest do
    end
    """
    |> source(path)
    |> run_task(TestFile, autocorrect: true)
    |> assert_issue_with(reporter: TestFile)
  end

  test "reports no issues" do
    path = "test/foo_test.exs"

    ":test"
    |> source(path)
    |> run_task(TestFile, autocorrect: false)
    |> refute_issues()
  end
end
