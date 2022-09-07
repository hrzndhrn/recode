defmodule Recode.FormatterTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Recode.Formatter
  alias Recode.Task.Format
  alias Rewrite.Issue
  alias Rewrite.Project
  alias Rewrite.Source

  @config verbose: true
  @opts []

  describe "formatter/3" do
    test "formats results for a project without changes" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source = Source.from_string(code)

      project = Project.from_sources([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, {project, @config}, @opts)
        end)

      assert strip_esc_seq(output) == ""
    end

    test "formats results for a project with changed source" do
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
          Formatter.format(:results, {project, @config}, @opts)
        end)

      assert strip_esc_seq(output) == """
              File: no file
             Updates: 1
             Changed by: test
             1 1   |defmodule Foo do
             2   - |  def bar, do: :foo
               2 + |  def foo, do: :foo
             3 3   |end
             4 4   |

             """
    end

    test "formats results for a project with changed and reverted source" do
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
          Formatter.format(:results, {project, @config}, @opts)
        end)

      assert strip_esc_seq(output) == """
              File: no file
             Updates: 2
             Changed by: test, test

             """
    end

    test "formats results for a project with changed source in big file" do
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
          Formatter.format(:results, {project, @config}, @opts)
        end)

      output = strip_esc_seq(output)

      assert output =~ "...|"
    end

    test "formats results for a project with moved source" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source =
        code
        |> Source.from_string("foo.ex")
        |> Source.update(:test, path: "bar.ex")

      project = Project.from_sources([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, {project, @config}, @opts)
        end)

      assert strip_esc_seq(output) == """
              File: bar.ex
             Updates: 1
             Changed by: test
             Moved from: foo.ex

             """
    end

    test "formats results for a project with issues" do
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
          Formatter.format(:results, {project, @config}, @opts)
        end)

      output = strip_esc_seq(output)

      assert output == """
              File: no file
             [foo 1/2] do not do this
             [bar 2/3] no no no

             """
    end

    test "formats results for a project with Recode.Runner issues" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source =
        code
        |> Source.from_string()
        |> Source.add_issue(Issue.new(Recode.Runner, task: Test, error: :error))

      project = Project.from_sources([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, {project, @config}, @opts)
        end)

      output = strip_esc_seq(output)

      assert output == """
              File: no file
             Execution of the Elixir.Test task failed.
             """
    end

    test "formats project infos" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source = Source.from_string(code)

      project = Project.from_sources([source])

      output =
        capture_io(fn ->
          Formatter.format(:project, {project, @config}, @opts)
        end)

      assert strip_esc_seq(output) == "Found 1 files, including 0 scripts.\n"
    end

    test "formats when tasks ready for an empty project" do
      project = Project.from_sources([])
      assert Formatter.format(:tasks_ready, {project, @config}, @opts) == :ok
    end

    test "formats when tasks ready" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source = Source.from_string(code)

      project = Project.from_sources([source])

      output =
        capture_io(fn ->
          Formatter.format(:tasks_ready, {project, @config}, @opts) == :ok
        end)

      assert output == "\n"
    end
  end

  describe "formatter/4" do
    test "formats task info" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source = Source.from_string(code)

      project = Project.from_sources([source])

      output =
        capture_io(fn ->
          Formatter.format(:task, {project, @config}, {source, Format, []}, @opts)
        end)

      assert strip_esc_seq(output) == "."
    end
  end

  defp strip_esc_seq(string) do
    string
    |> String.replace(~r/\e[^m]+m/, "")
    |> String.split("\n")
    |> Enum.map_join("\n", &String.trim_trailing/1)
  end
end
