defmodule Recode.Task.FormatTest do
  use RecodeCase

  alias Recode.Task.Format
  alias Rewrite.Source

  test "keeps formatted code" do
    """
    defmodule MyModule do
      def foo, do: :foo
    end
    """
    |> run_task(Format, autocorrect: true)
    |> refute_update()
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

    code
    |> run_task(Format, autocorrect: true)
    |> assert_code(expected)
  end

  test "formats the code and ignores the Recode.FormatterPlugin" do
    code = """
    defmodule MyModule do
      import Bar

      def foo(  x  ) do
        bar    x
      end
    end
    """

    expected = """
    defmodule MyModule do
      import Bar

      def foo(x) do
        bar x
      end
    end
    """

    source =
      code
      |> source()
      |> Source.Ex.put_formatter_opts(
        plugins: [Recode.FormatterPlugin],
        locals_without_parens: [bar: 1]
      )

    source
    |> run_task(Format, autocorrect: true)
    |> assert_code(expected)
  end

  test "formats the code with a plugin" do
    code = """
    defmodule MyModule do
      def foo(  x  ), do: {:foo,  x}
    end
    """

    expected = """
    defmodule MyModule do
      def foo(x) do
        {:foo, x}
      end
    end
    """

    source =
      code
      |> source()
      |> Source.Ex.put_formatter_opts(plugins: [FakePlugin])

    source
    |> run_task(Format, autocorrect: true)
    |> assert_code(expected)
  end

  test "formats an empty string" do
    code = "  "
    expected = "\n"

    code
    |> run_task(Format, autocorrect: true)
    |> assert_code(expected)
  end

  test "reports no issues" do
    code = """
    defmodule MyModule do
      def foo, do: :foo
    end
    """

    code
    |> run_task(Format, autocorrect: false)
    |> refute_issues()
  end

  test "reports an issue" do
    code = """
    defmodule MyModule do

      def foo, do: :foo
    end
    """

    code
    |> run_task(Format, autocorrect: false)
    |> assert_issue()
  end
end
