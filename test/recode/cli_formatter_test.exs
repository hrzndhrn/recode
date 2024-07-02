defmodule Recode.CLIFormatterTest do
  use ExUnit.Case

  import ExUnit.CaptureIO
  import Strip

  alias Recode.CLIFormatter
  alias Recode.Issue
  alias Rewrite.Source

  @config verbose: true

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
        format({:tasks_finished, project, 10_000})
      end)

    assert output |> strip_esc_seq() == """
           Executed 0 tasks in 0.01s.
           Files: 1 (.ex: 1)
           Everything ok
           """
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
        format({:tasks_finished, project, 10_000},
          times: [{TaTask, 1}, {DaTask, 2}],
          corrector_tasks_finished: 20_000,
          checker_tasks_finished: 12_345
        )
      end)

    assert output |> strip_esc_seq() == """
           File: test/formatter_test.ex
           Updates: 1
           Changed by: test
           1 1   |defmodule Foo do
           2   - |  def bar, do: :foo
             2 + |  def foo, do: :foo
           3 3   |end
           4 4   |

           Executed 0 tasks in 0.01s.
           Files: 1 (.ex: 1)
           Updated 1 file
           Everything ok
           """
  end

  test "formats results for a project with changed sources" do
    code = """
    defmodule Foo do
      def bar, do: :foo
    end
    """

    source_a =
      code
      |> from_string(path: "lib/a.ex")
      |> Source.update(:test, :content, String.replace(code, "bar", "foo"))

    source_b =
      code
      |> from_string(path: "lib/b.ex")
      |> Source.update(:test, :content, String.replace(code, "bar", "foo"))

    project = Rewrite.from_sources!([source_a, source_b])

    output =
      capture_io(fn ->
        format({:tasks_finished, project, 10_000})
      end)

    assert output |> strip_esc_seq() == """
           File: lib/a.ex
           Updates: 1
           Changed by: test
           1 1   |defmodule Foo do
           2   - |  def bar, do: :foo
             2 + |  def foo, do: :foo
           3 3   |end
           4 4   |

           File: lib/b.ex
           Updates: 1
           Changed by: test
           1 1   |defmodule Foo do
           2   - |  def bar, do: :foo
             2 + |  def foo, do: :foo
           3 3   |end
           4 4   |

           Executed 0 tasks in 0.01s.
           Files: 2 (.ex: 2)
           Updated 2 files
           Everything ok
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
        format({:tasks_finished, project, 10_000})
      end)

    assert output |> strip_esc_seq() == """
           File: test/formatter_test.ex
           Updates: 2
           Changed by: test, test

           Executed 0 tasks in 0.01s.
           Files: 1 (.ex: 1)
           Updated 1 file
           Everything ok
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
        format({:tasks_finished, project, 10_000})
      end)

    output = strip_esc_seq(output)

    assert output |> strip_esc_seq() =~ "...|"
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
        format({:tasks_finished, project, 10_000})
      end)

    assert output |> strip_esc_seq() == """
           File: bar.ex
           Updates: 1
           Changed by: test
           Moved from: foo.ex

           Executed 0 tasks in 0.01s.
           Files: 1 (.ex: 1)
           Moved 1 file
           Everything ok
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
        format({:tasks_finished, project, 10_000})
      end)

    assert output |> strip_esc_seq() == """
           File: foo.ex
           New file

           Executed 0 tasks in 0.01s.
           Files: 1 (.ex: 1)
           Created 1 file
           Everything ok
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
        format({:tasks_finished, project, 10_000})
      end)

    assert output |> strip_esc_seq() == """
           File: foo.ex
           New file, created by Test

           Executed 0 tasks in 0.01s.
           Files: 1 (.ex: 1)
           Created 1 file
           Everything ok
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
        format({:tasks_finished, project, 10_000})
      end)

    output = strip_esc_seq(output)

    assert output |> strip_esc_seq() == """
           File: test/formatter_test.ex
           [foo 1/2] do not do this
           [bar 2/3] no no no

           Executed 0 tasks in 0.01s.
           Files: 1 (.ex: 1)
           Found 2 issues
           """
  end

  test "formats results for a project with issues sorting by line" do
    code = """
    defmodule Foo do
      def bar, do: :foo
    end
    """

    source =
      code
      |> from_string()
      |> Source.add_issues([
        Issue.new(:foo, "no", line: 1, column: 2),
        Issue.new(:foo, "no", line: 3, column: 1),
        Issue.new(:foo, "no", line: 2, column: 3)
      ])

    project = Rewrite.from_sources!([source])

    output =
      capture_io(fn ->
        format({:tasks_finished, project, 10_000})
      end)

    output = strip_esc_seq(output)

    assert output |> strip_esc_seq() == """
           File: test/formatter_test.ex
           [foo 1/2] no
           [foo 2/3] no
           [foo 3/1] no

           Executed 0 tasks in 0.01s.
           Files: 1 (.ex: 1)
           Found 3 issues
           """
  end

  test "formats results for a project with issues sorting by column" do
    code = """
    defmodule Foo do
      def bar, do: :foo
    end
    """

    source =
      code
      |> from_string()
      |> Source.add_issues([
        Issue.new(:foo, "no", line: 2, column: 2),
        Issue.new(:foo, "no", line: 2, column: 1),
        Issue.new(:foo, "no", line: 2, column: 3)
      ])

    project = Rewrite.from_sources!([source])

    output =
      capture_io(fn ->
        format({:tasks_finished, project, 10_000})
      end)

    output = strip_esc_seq(output)

    assert output |> strip_esc_seq() == """
           File: test/formatter_test.ex
           [foo 2/1] no
           [foo 2/2] no
           [foo 2/3] no

           Executed 0 tasks in 0.01s.
           Files: 1 (.ex: 1)
           Found 3 issues
           """
  end

  test "formats results for a project with issues and afterwars changed source" do
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
      |> Source.update(TestTask, :content, String.replace(code, ":foo", ":bar"))

    project = Rewrite.from_sources!([source])

    output =
      capture_io(fn ->
        format({:tasks_finished, project, 10_000})
      end)

    output = strip_esc_seq(output)

    assert output |> strip_esc_seq() == """
           File: test/formatter_test.ex
           Updates: 1
           Changed by: TestTask
           1 1   |defmodule Foo do
           2   - |  def bar, do: :foo
             2 + |  def bar, do: :bar
           3 3   |end
           4 4   |
           Version 1/2 [foo 1/2] do not do this
           Version 1/2 [bar 2/3] no no no

           Executed 0 tasks in 0.01s.
           Files: 1 (.ex: 1)
           Updated 1 file
           Found 2 issues
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
        format({:tasks_finished, project, 10_000})
      end)

    output = strip_esc_seq(output)

    assert output |> strip_esc_seq() == """
           File: test/formatter_test.ex
           Execution of the Test task failed with error:
           Error Message

           Executed 0 tasks in 0.01s.
           Files: 1 (.ex: 1)
           Found 1 issue
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
        format({:prepared, project, 9999})
      end)

    assert strip_esc_seq(output) == "Read 1 file\n"
  end

  test "formats when tasks ready for an empty project" do
    project = Rewrite.from_sources!([])

    output =
      capture_io(fn ->
        assert format({:tasks_finished, project, 10_000})
      end)

    assert output == ""
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
        assert format({:tasks_finished, project, 10_000})
      end)

    assert output |> strip_esc_seq() == """
           Executed 0 tasks in 0.01s.
           Files: 1 (.ex: 1)
           Everything ok
           """
  end

  test "formats task started info" do
    code = """
    defmodule Foo do
      def bar, do: :foo
    end
    """

    source = from_string(code)

    output =
      capture_io(fn ->
        format({:task_started, source, TaTask})
      end)

    assert strip_esc_seq(output) == ""
  end

  test "formats task started info with debug flag" do
    code = """
    defmodule Foo do
      def bar, do: :foo
    end
    """

    source = from_string(code)

    output =
      capture_io(fn ->
        format({:task_started, source, TaTask}, debug: true)
      end)

    assert strip_esc_seq(output) == "Start Elixir.TaTask with test/formatter_test.ex.\n"
  end

  test "formats task finished info without an issue" do
    code = """
    defmodule Foo do
      def bar, do: :foo
    end
    """

    source = from_string(code)

    output =
      capture_io(fn ->
        format({:task_finished, source, TaTask, 1})
      end)

    assert strip_esc_seq(output) == "."
  end

  test "formats task finished info with an issue" do
    code = """
    defmodule Foo do
      def bar, do: :foo
    end
    """

    source =
      code
      |> from_string()
      |> Source.add_issue(Issue.new(TaTask, "do not do this", line: 1, column: 2))

    output =
      capture_io(fn ->
        format({:task_finished, source, TaTask, 1})
      end)

    assert strip_esc_seq(output) == "!"
  end

  test "formats task finished info with an updated source" do
    code = """
    defmodule Foo do
      def bar, do: :foo
    end
    """

    source =
      code
      |> from_string()
      |> Source.update(TaTask, :content, String.replace(code, ":foo", ":bar"))

    output =
      capture_io(fn ->
        format({:task_finished, source, TaTask, 1})
      end)

    assert strip_esc_seq(output) == "!"
  end

  test "formats task finished info with debug flag" do
    code = """
    defmodule Foo do
      def bar, do: :foo
    end
    """

    source = from_string(code)

    output =
      capture_io(fn ->
        format({:task_finished, source, TaTask, 10_000}, debug: true)
      end)

    assert strip_esc_seq(output) ==
             "Finished Elixir.TaTask with test/formatter_test.ex [10000μs].\n"
  end

  defp format(message, opts \\ []) do
    {:ok, formatter} = GenServer.start_link(CLIFormatter, Keyword.merge(@config, opts))
    GenServer.cast(formatter, message)
    GenServer.stop(formatter)
  end

  defp from_string(string, opts \\ []) do
    {path, opts} = Keyword.pop(opts, :path, "test/formatter_test.ex")

    source = Source.Ex.from_string(string, path)

    opts = Keyword.put_new(opts, :from, :file)

    Enum.reduce(opts, source, fn {key, value}, source ->
      Map.put(source, key, value)
    end)
  end
end
