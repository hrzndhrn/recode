defmodule Recode.Task.FormatTest do
  use RecodeCase

  alias Recode.Task.Format

  defp run(code, opts \\ [autocorrect: true]) do
    code |> source() |> run_task({Format, opts})
  end

  test "keeps formatted code" do
    code = """
    defmodule MyModule do
      def foo, do: :foo
    end
    """

    source = run(code)

    assert_code source == code
  end

  test "formats the code" do
    code = """
    defmodule MyModule do

      def foo,     do: :foo
    end
    """

    expected = """
    defmodule MyModule do
      def foo, do: :foo
    end
    """

    source = run(code)

    assert_code source == expected
  end

  test "reports no issues" do
    code = """
    defmodule MyModule do
      def foo, do: :foo
    end
    """

    source = run(code, autocorrect: false)

    assert_no_issues(source)
  end

  test "reports an issue" do
    code = """
    defmodule MyModule do

      def foo, do: :foo
    end
    """

    source = run(code, autocorrect: false)

    assert_issue(source, Format)
  end
end
