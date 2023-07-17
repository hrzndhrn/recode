defmodule Recode.FormatterTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Recode.Formatter
  alias Recode.Issue
  alias Recode.Task.Format
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

      source = from_string(code)

      project = Rewrite.from_sources!([source])

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
        |> from_string()
        |> Source.update(:test, :content, String.replace(code, "bar", "foo"))

      project = Rewrite.from_sources!([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, {project, @config}, @opts)
        end)

      assert strip_esc_seq(output) == """
              File: test/formatter_test.ex
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
        |> from_string()
        |> Source.update(:test, :content, String.replace(code, "bar", "foo"))
        |> Source.update(:test, :content, code)

      project = Rewrite.from_sources!([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, {project, @config}, @opts)
        end)

      assert strip_esc_seq(output) == """
              File: test/formatter_test.ex
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
        |> from_string()
        |> Source.update(:test, :content, String.replace(code, "bar", "foo"))

      project = Rewrite.from_sources!([source])

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
        |> from_string(path: "foo.ex")
        |> Source.update(:test, :path, "bar.ex")

      project = Rewrite.from_sources!([source])

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

    test "formats results for a project with created source" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source = from_string(code, path: "foo.ex", from: :string)
      project = Rewrite.from_sources!([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, {project, @config}, @opts)
        end)

      assert strip_esc_seq(output) == """
              File: foo.ex
             New file

             """
    end

    test "formats results for a project with created source by Test" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source = from_string(code, path: "foo.ex", from: :string, owner: Test)
      project = Rewrite.from_sources!([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, {project, @config}, @opts)
        end)

      assert strip_esc_seq(output) == """
              File: foo.ex
             New file, created by Test

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
        |> from_string()
        |> Source.add_issues([
          Issue.new(:foo, "do not do this", line: 1, column: 2),
          Issue.new(:bar, "no no no", line: 2, column: 3)
        ])

      project = Rewrite.from_sources!([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, {project, @config}, @opts)
        end)

      output = strip_esc_seq(output)

      assert output == """
              File: test/formatter_test.ex
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
        |> from_string()
        |> Source.add_issue(
          Issue.new(Recode.Runner, task: Test, error: :error, message: "Error Message")
        )

      project = Rewrite.from_sources!([source])

      output =
        capture_io(fn ->
          Formatter.format(:results, {project, @config}, @opts)
        end)

      output = strip_esc_seq(output)

      assert output == """
              File: test/formatter_test.ex
             Execution of the Test task failed with error:
             Error Message
             """
    end

    test "formats project infos" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source = from_string(code)

      project = Rewrite.from_sources!([source])

      output =
        capture_io(fn ->
          Formatter.format(:project, {project, @config}, @opts)
        end)

      assert strip_esc_seq(output) == "Found 1 files, including 0 scripts.\n"
    end

    test "formats when tasks ready for an empty project" do
      project = Rewrite.from_sources!([])
      assert Formatter.format(:tasks_ready, {project, @config}, @opts) == :ok
    end

    test "formats when tasks ready" do
      code = """
      defmodule Foo do
        def bar, do: :foo
      end
      """

      source = from_string(code)

      project = Rewrite.from_sources!([source])

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

      source = from_string(code)

      project = Rewrite.from_sources!([source])

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

  defp from_string(string, opts \\ []) do
    source = Source.Ex.from_string(string, "test/formatter_test.ex")

    opts = Keyword.put_new(opts, :from, :file)

    Enum.reduce(opts, source, fn {key, value}, source ->
      Map.put(source, key, value)
    end)
  end
end
