defmodule Recode.Runner.ImplTest do
  use RecodeCase

  import ExUnit.CaptureIO
  import Mox
  import Strip

  alias Recode.Runner.Impl, as: Runner
  alias Recode.Task.AliasOrder
  alias Recode.Task.SinglePipe
  alias Recode.TaskMock
  alias Rewrite.DotFormatter
  alias Rewrite.Source

  @task_config __recode_task_config__: [checker: true, corrector: true]

  setup :verify_on_exit!

  @default_config [
    autocorrect: true,
    dry: false,
    verbose: false,
    silent: false,
    inputs: ["{config,lib,test}/**/*.{ex,exs}"],
    formatters: [Recode.CLIFormatter],
    tasks: [
      {Task.SinglePipe, []},
      {Task.PipeFunOne, []},
      {Task.AliasExpansion, []}
    ]
  ]

  # Merges the default configuration with test-specific overrides.
  defp config(merge) do
    Keyword.merge(@default_config, merge)
  end

  describe "run/1" do
    @describetag :tmp_dir

    @tag fixture: "runner"
    test "runs tasks from config", context do
      in_tmp context do
        config = config(dry: true, verbose: true, tasks: [{SinglePipe, []}])

        capture_io(fn ->
          assert {:ok, 0} = Runner.run(config)
        end)
      end
    end

    @tag fixture: "runner"
    test "runs tasks from config with no color", context do
      in_tmp context do
        config = config(dry: true, verbose: true, color: false, tasks: [{SinglePipe, []}])

        output =
          capture_io(fn ->
            assert {:ok, 0} = Runner.run(config)
          end)

        assert output =~ "Read 2 files in"
        assert output =~ "Everything ok"

        # Verify no ANSI escape sequences
        assert not String.contains?(output, "\e[")
      end
    end

    @tag fixture: "runner"
    test "runs tasks from config (autocorrect: false)", context do
      in_tmp context do
        config = config(dry: true, autocorrect: false, tasks: [{SinglePipe, []}])

        capture_io(fn ->
          assert {:ok, 0} = Runner.run(config)
        end)
      end
    end

    @tag fixture: "runner"
    test "runs tasks from config (check: false)", context do
      in_tmp context do
        config =
          config(
            dry: true,
            autocorrect: true,
            check: false,
            tasks: [{SinglePipe, []}]
          )

        capture_io(fn ->
          assert {:ok, 0} = Runner.run(config)
        end)
      end
    end

    @tag fixture: "runner"
    test "runs tasks from config with cli_opts", context do
      in_tmp context do
        config =
          config(
            dry: true,
            autocorrect: true,
            check: false,
            tasks: [{AliasOrder, []}],
            cli_opts: [tasks: [], dry: true, autocorrect: false]
          )

        output =
          capture_io(fn ->
            assert {:ok, 1} = Runner.run(config)
          end)

        assert strip_esc_seq(output) =~ "[AliasOrder 3/3] The alias `Alpha` is not"
      end
    end

    @tag fixture: "runner"
    test "runs tasks from cli_opts", context do
      in_tmp context do
        config =
          config(
            dry: true,
            autocorrect: true,
            check: false,
            tasks: [{AliasOrder, []}],
            cli_opts: [tasks: ["SinglePipe"]]
          )

        capture_io(fn ->
          assert {:ok, 0} = Runner.run(config)
        end)
      end
    end

    @tag fixture: "runner"
    test "runs tasks from cli_opts and overrides active", context do
      in_tmp context do
        config =
          config(
            autocorrect: false,
            tasks: [{AliasOrder, [active: false]}],
            cli_opts: [tasks: ["AliasOrder"]]
          )

        capture_io(fn ->
          assert {:ok, 1} = Runner.run(config)
        end)
      end
    end

    @tag fixture: "runner"
    test "suppresses output in silent mode", context do
      in_tmp context do
        config = config(silent: true, tasks: [{SinglePipe, []}])

        output =
          capture_io(fn ->
            assert {:ok, 0} = Runner.run(config)
          end)

        assert output == ""
      end
    end

    @tag fixture: "runner"
    test "suppresses info output in silent mode with verbose", context do
      in_tmp context do
        config = config(silent: true, verbose: true, color: false, tasks: [{SinglePipe, []}])
        File.write("lib/bar.ex", "x |> to_string()\n")

        output =
          capture_io(fn ->
            assert {:ok, 0} = Runner.run(config)
          end)

        assert output =~ "File: lib/bar.ex"
        assert output =~ "Changed by: SinglePipe"
      end
    end

    @tag fixture: "runner"
    test "prints issues even in silent mode", context do
      in_tmp context do
        config =
          config(
            silent: true,
            verbose: false,
            autocorrect: false,
            color: false,
            tasks: [{SinglePipe, []}]
          )

        File.write("lib/bar.ex", "x |> to_string()\n")

        output =
          capture_io(fn ->
            assert {:ok, 1} = Runner.run(config)
          end)

        assert output =~ "File: lib/bar.ex\n[SinglePipe 1/3] Use a function"
      end
    end

    @tag fixture: "runner"
    test "runs task with the right config", context do
      in_tmp context do
        TaskMock
        |> expect(:run, 2, fn source, config ->
          assert config[:autocorrect] == true
          assert config[:dot_formatter] == DotFormatter.default()
          source
        end)
        |> expect(:__attributes__, fn -> @task_config end)

        config = config(tasks: [{TaskMock, []}])

        output =
          capture_io(fn ->
            assert Runner.run(config)
          end)

        assert output =~ "Everything ok"
      end
    end

    @tag fixture: "runner"
    test "runs task with the right additional config", context do
      in_tmp context do
        TaskMock
        |> expect(:run, 2, fn source, config ->
          assert {:ok, config} = Keyword.validate(config, [:autocorrect, :foo, :dot_formatter])
          assert config[:autocorrect] == true
          assert config[:dot_formatter] == DotFormatter.default()
          assert config[:foo] == :bar
          source
        end)
        |> expect(:__attributes__, fn -> @task_config end)

        config = config(tasks: [{TaskMock, config: [foo: :bar]}])

        capture_io(fn ->
          assert Runner.run(config)
        end)
      end
    end

    @tag fixture: "runner"
    test "runs task with input from stdin", context do
      in_tmp context do
        config = config(inputs: "-", tasks: [{TaskMock, []}])
        code = ":foo |> bar()\n"

        TaskMock
        |> expect(:run, fn source, _config ->
          assert source.content == code
          Source.update(source, :content, "bar(:foo)")
        end)
        |> expect(:__attributes__, fn -> @task_config end)

        capture_io(code, fn ->
          assert Runner.run(code, config) == "bar(:foo)\n"
        end)
      end
    end

    @tag fixture: "runner"
    test "does not run task with active: false", context do
      in_tmp context do
        TaskMock
        |> expect(:run, 2, fn source, config ->
          assert config[:foo] == :bar
          source
        end)
        |> expect(:__attributes__, fn -> @task_config end)

        config =
          config(
            tasks: [
              {TaskMock, config: [foo: :bar]},
              {TaskMock, active: false, config: [foo: :none]}
            ]
          )

        capture_io(fn ->
          assert Runner.run(config)
        end)
      end
    end

    @tag fixture: "runner"
    test "does not run task for excluded files", context do
      in_tmp context do
        TaskMock
        |> expect(:run, 1, fn source, _config -> source end)
        |> expect(:__attributes__, fn -> @task_config end)

        config =
          config(
            tasks: [
              {TaskMock, exclude: "**/*.exs", config: [foo: :bar]}
            ]
          )

        io =
          capture_io(fn ->
            assert Runner.run(config)
          end)

        # one dot per file and task
        assert strip_esc_seq(io) =~ ~r/\n\.\n/
      end
    end

    @tag fixture: "runner"
    test "runs task throwing exception", context do
      in_tmp context do
        TaskMock
        |> expect(:run, 2, fn _source, _config ->
          raise "An Exception Occurred"
        end)
        |> expect(:__attributes__, fn -> @task_config end)

        config = config(tasks: [{TaskMock, []}])

        io =
          capture_io(fn ->
            assert {:ok, 1} = Runner.run(config)
          end)

        assert io =~ "Execution of the Recode.TaskMock task failed."
      end
    end

    @tag fixture: "runner"
    test "throws an exception for an invalid formatter", context do
      in_tmp context do
        config =
          config(
            dry: true,
            formatters: [Foo]
          )

        assert_raise RuntimeError, fn -> Runner.run(config) end
      end
    end

    test "formats files", context do
      in_tmp context do
        config = config(dry: false, tasks: [], inputs: "**")

        File.write!("foo.ex", "foo bar baz")

        capture_io(fn ->
          assert {:ok, 0} = Runner.run(config)
        end)

        assert File.read!("foo.ex") == "foo(bar(baz))\n"
      end
    end

    test "formats files with .formatter.exs", context do
      in_tmp context do
        config = config(dry: false, tasks: [], inputs: "**")

        File.write!(".formatter.exs", """
        [inputs: "**",
         locals_without_parens: [foo: 1]]
        """)

        File.write!("foo.ex", """
        foo bar baz
        """)

        capture_io(fn ->
          assert {:ok, 0} = Runner.run(config)
        end)

        assert File.read!("foo.ex") == """
               foo bar(baz)
               """

        assert File.read!(".formatter.exs") == """
               [inputs: \"**\", locals_without_parens: [foo: 1]]
               """
      end
    end

    if function_exported?(FreedomFormatter, :features, 1) do
      test "formats files with .formatter.exs and respects plugins", context do
        in_tmp context do
          config = config(dry: false, tasks: [{SinglePipe, []}], inputs: "**")

          File.write!(".formatter.exs", """
          [
           inputs: "**",
           locals_without_parens: [foo: 1],
           plugins: [FreedomFormatter],
            trailing_comma: true
          ]
          """)

          File.write!("foo.ex", """
          [
          :foo,
          :bar,
          :baz,
          ] |> foo
          """)

          capture_io(fn ->
            assert {:ok, 0} = Runner.run(config)
          end)

          assert File.read!("foo.ex") == """
                 foo [
                   :foo,
                   :bar,
                   :baz,
                 ]
                 """

          assert File.read!(".formatter.exs") == """
                 [
                   inputs: "**",
                   locals_without_parens: [foo: 1],
                   plugins: [FreedomFormatter],
                   trailing_comma: true,
                 ]
                 """
        end
      end
    end

    test "reads inputs from .formatter.exs", context do
      in_tmp context do
        config = config(inputs: :formatter, dry: false, tasks: [{SinglePipe, []}])

        File.write!(".formatter.exs", ~s|[inputs: "lib/**/*.ex", subdirectories: ["bar"]]|)
        File.mkdir!("lib")
        File.write!("lib/foo.ex", " foo  =  :foo")
        File.mkdir!("bar")
        File.write!("bar/.formatter.exs", ~s|[inputs: "**/*.ex"]|)
        File.write!("bar/foo.ex", " foo  =  :foo")

        capture_io(fn ->
          assert {:ok, 0} = Runner.run(config)
        end)

        code = "foo = :foo\n"
        assert File.read!("bar/foo.ex") == code
        assert File.read!("lib/foo.ex") == code
      end
    end

    test "adds formatter issues to sources", context do
      in_tmp context do
        config = config(dry: true, color: false, tasks: [])

        code = """
        defmodule Foo do
                def bar, do: :baz
        end
        """

        File.mkdir!("lib")
        File.write!("lib/foo.ex", code)

        output =
          capture_io(fn ->
            assert {:ok, 1} = Runner.run(config)
          end)

        assert File.read!("lib/foo.ex") == code
        assert output =~ "lib/foo.ex"
        assert output =~ "The file is not formatted."
      end
    end

    test "reads inputs from .formatter.exs and glob expression", context do
      in_tmp context do
        config =
          config(inputs: [:formatter, "bar/**/*.ex"], dry: false, tasks: [{SinglePipe, []}])

        File.write!(".formatter.exs", ~s|[inputs: "lib/**/*.ex"]|)
        File.mkdir!("lib")
        File.write!("lib/foo.ex", " :foo |> foo")
        File.mkdir!("bar")
        File.write!("bar/foo.ex", " :foo |> foo")

        capture_io(fn ->
          assert {:ok, 0} = Runner.run(config)
        end)

        code = "foo(:foo)\n"
        assert File.read!("lib/foo.ex") == code
        assert File.read!("bar/foo.ex") == code
      end
    end
  end

  describe "run/3" do
    @describetag :tmp_dir

    @tag fixture: "runner"
    test "runs task with a source", context do
      in_tmp context do
        config = config(tasks: [{SinglePipe, []}])

        code = "x |> Enum.reverse()"

        assert Runner.run(code, config, "source.ex") == """
               Enum.reverse(x)
               """
      end
    end

    @tag fixture: "runner"
    test "runs task with an empty string", context do
      in_tmp context do
        config = config(tasks: [{SinglePipe, []}])

        assert Runner.run("", config, "source.ex") == ""
      end
    end

    @tag fixture: "runner"
    test "runs task with an excluded source", context do
      in_tmp context do
        config = config(tasks: [{SinglePipe, [exclude: "foo/**"]}])

        code = "x |> Enum.reverse()\n"

        assert Runner.run(code, config, "foo/source.ex") == code
      end
    end

    test "formats code with .formatter.exs", context do
      in_tmp context do
        config = config(dry: false, tasks: [], inputs: "**")

        File.write!(".formatter.exs", """
        [
          inputs: "lib/**/*.ex",
          locals_without_parens: [bar: 1]
        ]
        """)

        code = """
        foo bar baz
        """

        # Fake here what `mix format` does.
        dot_formatter = DotFormatter.read!()
        config = Keyword.put(config, :formatter_opts, DotFormatter.formatter_opts(dot_formatter))

        assert Runner.run(code, config, "my_code.exs") == """
               foo(bar baz)
               """
      end
    end

    if function_exported?(FreedomFormatter, :features, 1) do
      test "formats code with .formatter.exs and respects plugins", context do
        in_tmp context do
          config = config(dry: false, tasks: [{SinglePipe, []}], inputs: "**")

          File.write!(".formatter.exs", """
          [
            inputs: "**",
            locals_without_parens: [foo: 1],
            plugins: [FreedomFormatter],
            trailing_comma: true
          ]
          """)

          code = """
          [
          :foo,
          :bar,
          :baz,
          ] |> foo
          """

          # Fake here what `mix format` does.
          dot_formatter = DotFormatter.read!()

          config =
            Keyword.put(config, :formatter_opts, DotFormatter.formatter_opts(dot_formatter))

          assert Runner.run(code, config, "my_code.exs") == """
                 foo [
                   :foo,
                   :bar,
                   :baz,
                 ]
                 """
        end
      end
    end
  end
end
