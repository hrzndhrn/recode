defmodule Recode.FormatterTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Recode.Formatter
  alias Recode.Project
  alias Recode.Source

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
          assert Formatter.format(project, [], []) == project
        end)

      assert strip_esc_seq(output) == "File: no file Updates: 0\n"
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
          assert Formatter.format(project, [], []) == project
        end)

      assert strip_esc_seq(output) == """
             File: no file Updates: 1
             Changed by: :test
             001|defmodule Foo do
             002|  def bar, do: :foo
             002|  def foo, do: :foo
             003|end
             004|

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
          assert Formatter.format(project, [], []) == project
        end)

      assert strip_esc_seq(output) == """
             File: no file Updates: 2
             Changed by: :test, :test
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
          assert Formatter.format(project, [], []) == project
        end)

      output = strip_esc_seq(output)

      assert output =~ "...|"
    end
  end

  defp strip_esc_seq(string), do: String.replace(string, ~r/\e[^m]+m/, "")
end
