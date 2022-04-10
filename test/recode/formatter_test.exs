defmodule Recode.FormatterTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Recode.Formatter
  alias Recode.Issue
  alias Recode.Project
  alias Recode.Source

  @config verbose: true
  @opts []

  describe "formatter/3" do
    test "formats a project" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source = Source.from_string(code)

      project = Project.from_sources([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, project, @opts, @config)
        end)

      assert strip_esc_seq(output) == ""
    end

    test "formats a project with changed source" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source =
        code
        |> Source.from_string()
        |> Source.update(:test, code: String.replace(code, "bar", "foo"))

      project = Project.from_sources([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, project, @opts, @config)
        end)

      assert strip_esc_seq(output) == """
              File: no file
             Updates: 1
             Changed by: test
             001   |defmodule Foo do
             002 - |  def bar, do: :foo
             002 + |  def foo, do: :foo
             003   |end
             004   |

             """
    end

    test "formats a project with changed and reverted source" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source =
        code
        |> Source.from_string()
        |> Source.update(:test, code: String.replace(code, "bar", "foo"))
        |> Source.update(:test, code: code)

      project = Project.from_sources([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, project, @opts, @config)
        end)

      assert strip_esc_seq(output) == """
              File: no file
             Updates: 2
             Changed by: test, test

             """
    end

    test "formats a project with changed source in big file" do
      code = """
      defmodule Foo do
        # Not really a very big file ;-)

        def bar, do: :foo

        # no comment
        # no comment
        # no comment
        # no comment
        # no comment
        # no comment
        # no comment
        # no comment
        def bar(x), do: x

        def bar(a, b), do: a + b
      end
      """

      source =
        code
        |> Source.from_string()
        |> Source.update(:test, code: String.replace(code, "bar", "foo"))

      project = Project.from_sources([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, project, @opts, @config)
        end)

      output = strip_esc_seq(output)

      assert output =~ "...   |"
    end

    test "formats a project with issues" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source =
        code
        |> Source.from_string()
        |> Source.add_issues([
          Issue.new(:foo, "do not do this", line: 1, column: 2),
          Issue.new(:bar, "no no no", line: 2, column: 3)
        ])

      project = Project.from_sources([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, project, @opts, @config)
        end)

      output = strip_esc_seq(output)

      assert output == """
              File: no file
             [foo 1/2] do not do this
             [bar 2/3] no no no

             """
    end
  end

  defp strip_esc_seq(string) do
    string
    |> String.replace(~r/\e[^m]+m/, "")
    |> String.split("\n")
    |> Enum.map_join("\n", &String.trim_trailing/1)
  end
end
