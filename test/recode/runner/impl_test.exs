defmodule Recode.Runner.ImplTest do
  use ExUnit.Case

  import ExUnit.CaptureIO
  import Mox

  alias Recode.Runner.Impl, as: Runner
  alias Recode.Task.AliasOrder
  alias Recode.Task.SinglePipe
  alias Recode.TaskMock
  alias Rewrite.Source

  @task_config __recode_task_config__: [checker: true, corrector: true]

  setup :verify_on_exit!

  setup_all context do
    cwd = File.cwd!()
    File.cd!("test/fixtures/runner")

    config = "config.exs" |> Code.eval_file() |> elem(0)

    on_exit(fn ->
      File.cd(cwd)
    end)

    Map.put(context, :config, config)
  end

  describe "run/1" do
    test "runs tasks from config", %{config: config} do
      config = Keyword.merge(config, dry: true, verbose: true, tasks: [{SinglePipe, []}])

      capture_io(fn ->
        assert {:ok, 0} = Runner.run(config)
      end)
    end

    test "runs tasks from config (autocorrect: false)", %{config: config} do
      config = Keyword.merge(config, dry: true, autocorrect: false, tasks: [{SinglePipe, []}])

      capture_io(fn ->
        assert {:ok, 0} = Runner.run(config)
      end)
    end

    test "runs tasks from config (check: false)", %{config: config} do
      config =
        Keyword.merge(config,
          dry: true,
          autocorrect: true,
          check: false,
          tasks: [{SinglePipe, []}]
        )

      capture_io(fn ->
        assert {:ok, 0} = Runner.run(config)
      end)
    end

    test "runs tasks from config with cli_opts", %{config: config} do
      config =
        Keyword.merge(config,
          dry: true,
          autocorrect: true,
          check: false,
          tasks: [{AliasOrder, []}],
          cli_opts: [tasks: [], dry: true, autocorrect: false]
        )

      io =
        capture_io(fn ->
          assert {:ok, 1} = Runner.run(config)
        end)

      assert strip_esc_seq(io) =~ "[AliasOrder 3/3] The alias `Alpha` is not"
    end

    test "runs tasks from cli_opts", %{config: config} do
      config =
        Keyword.merge(config,
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

    test "runs tasks from cli_opts and overrides active", %{config: config} do
      config =
        Keyword.merge(config,
          autocorrect: false,
          tasks: [{AliasOrder, [active: false]}],
          cli_opts: [tasks: ["AliasOrder"]]
        )

      capture_io(fn ->
        assert {:ok, 1} = Runner.run(config)
      end)
    end

    test "runs task with the right config", %{config: config} do
      TaskMock
      |> expect(:run, 2, fn source, config ->
        assert config == [autocorrect: true]
        source
      end)
      |> expect(:__attributes__, fn -> @task_config end)

      config = Keyword.put(config, :tasks, [{TaskMock, []}])

      output =
        capture_io(fn ->
          assert Runner.run(config)
        end)

      assert output =~ "Everything ok"
    end

    test "runs task with the right aditional config", %{config: config} do
      TaskMock
      |> expect(:run, 2, fn source, config ->
        assert config == [autocorrect: true, foo: :bar]
        source
      end)
      |> expect(:__attributes__, fn -> @task_config end)

      config = Keyword.put(config, :tasks, [{TaskMock, config: [foo: :bar]}])

      capture_io(fn ->
        assert Runner.run(config)
      end)
    end

    test "runs task with input from stdin", %{config: config} do
      config = Keyword.merge(config, inputs: "-", tasks: [{TaskMock, []}])
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

    test "does not run task with active: false", %{config: config} do
      TaskMock
      |> expect(:run, 2, fn source, config ->
        assert config == [autocorrect: true, foo: :bar]
        source
      end)
      |> expect(:__attributes__, fn -> @task_config end)

      config =
        Keyword.put(config, :tasks, [
          {TaskMock, config: [foo: :bar]},
          {TaskMock, active: false, config: [foo: :none]}
        ])

      capture_io(fn ->
        assert Runner.run(config)
      end)
    end

    test "does not run task for excluded files", %{config: config} do
      TaskMock
      |> expect(:run, 1, fn source, config ->
        assert config == [autocorrect: true, foo: :bar]
        source
      end)
      |> expect(:__attributes__, fn -> @task_config end)

      config =
        Keyword.put(config, :tasks, [
          {TaskMock, exclude: "**/*.exs", config: [foo: :bar]}
        ])

      io =
        capture_io(fn ->
          assert Runner.run(config)
        end)

      # one dot per file and task
      assert strip_esc_seq(io) =~ ~r/\n\.\n/
    end

    test "runs task throwing exception", %{config: config} do
      TaskMock
      |> expect(:run, 2, fn _source, _config ->
        raise "An Exception Occurred"
      end)
      |> expect(:__attributes__, fn -> @task_config end)

      config = Keyword.put(config, :tasks, [{TaskMock, []}])

      io =
        capture_io(fn ->
          assert {:ok, 1} = Runner.run(config)
        end)

      assert io =~ "Execution of the Recode.TaskMock task failed."
    end

    test "throws an exception for an invalid formatter", %{config: config} do
      config =
        Keyword.merge(config,
          dry: true,
          formatters: [Foo]
        )

      assert_raise RuntimeError, fn -> Runner.run(config) end
    end
  end

  describe "run/2" do
    test "runs task with a source", %{config: config} do
      config = Keyword.put(config, :tasks, [{SinglePipe, []}])

      code = "x |> Enum.reverse()"

      assert Runner.run(code, config, "source.ex") == """
             Enum.reverse(x)
             """
    end

    test "runs task with an empty string", %{config: config} do
      config = Keyword.put(config, :tasks, [{SinglePipe, []}])

      assert Runner.run("", config, "source.ex") == ""
    end

    test "runs task with an excluded source", %{config: config} do
      config = Keyword.put(config, :tasks, [{SinglePipe, [exclude: "foo/**"]}])

      code = "x |> Enum.reverse()\n"

      assert Runner.run(code, config, "foo/source.ex") == code
    end
  end

  defp strip_esc_seq(string) do
    string
    |> String.replace(~r/\e[^m]+m/, "")
    |> String.split("\n")
    |> Enum.map_join("\n", &String.trim_trailing/1)
  end
end
