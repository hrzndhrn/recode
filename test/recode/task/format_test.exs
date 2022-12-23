defmodule Recode.Task.FormatTest do
  use RecodeCase

  alias Recode.Task.Format
  alias Rewrite.Source

  defp run(code, opts \\ [autocorrect: true])

  defp run(code, opts) when is_binary(code) do
    code |> source() |> run_task({Format, opts})
  end

  defp run(source, opts) when is_struct(source) do
    run_task(source, {Format, opts})
  end

  test "keeps formatted code" do
    code = """
    defmodule MyModule do
      def foo, do: :foo
    end
    """

    source = run(code)

    assert_code(source == code)
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

    assert_code(source == expected)
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

    source = run(source)

    assert_code(source == expected)
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

    source = run(source)

    assert_code(source == expected)
  end

  test "formats en empty string" do
    code = "  "
    expected = ""

    source = run(code)

    assert_code(source == expected)
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
