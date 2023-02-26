defmodule Recode.Runner.ImplTest do
  use ExUnit.Case

  import ExUnit.CaptureIO
  import Mox

  alias Recode.Runner.Impl, as: Runner
  alias Recode.Task.SinglePipe
  alias Recode.TaskMock
  alias Rewrite.Project
  alias Rewrite.Source

  setup :verify_on_exit!

  setup_all context do
    cwd = File.cwd!()
    File.cd!("test/fixtures/runner")

    config = "config.exs" |> Code.eval_file() |> elem(0)

    on_exit(fn -> File.cd(cwd) end)

    Map.put(context, :config, config)
  end

  describe "run/1" do
    test "runs tasks from config", %{config: config} do
      config = Keyword.merge(config, dry: true, verbose: true, tasks: [{SinglePipe, []}])

      capture_io(fn ->
        assert %Project{} = Runner.run(config)
      end)
    end

    test "runs tasks from config (autocorrect: false)", %{config: config} do
      config = Keyword.merge(config, dry: true, autocorrect: false, tasks: [{SinglePipe, []}])

      capture_io(fn ->
        assert %Project{} = Runner.run(config)
      end)
    end

    test "runs task with the right config", %{config: config} do
      TaskMock
      |> expect(:run, fn source, config ->
        assert config == [autocorrect: true]
        source
      end)
      |> expect(:config, fn :correct -> true end)

      config = Keyword.put(config, :tasks, [{TaskMock, []}])

      capture_io(fn ->
        assert Runner.run(config)
      end)
    end

    test "runs task with the right aditional config", %{config: config} do
      TaskMock
      |> expect(:run, fn source, config ->
        assert config == [autocorrect: true, foo: :bar]
        source
      end)
      |> expect(:config, fn :correct -> true end)

      config = Keyword.put(config, :tasks, [{TaskMock, config: [foo: :bar]}])

      capture_io(fn ->
        assert Runner.run(config)
      end)
    end

    test "runs task with input from stdin", %{config: config} do
      config = Keyword.merge(config, inputs: "-", tasks: [{TaskMock, []}])
      code = ":foo |> bar()"

      TaskMock
      |> expect(:run, fn source, _config ->
        assert source.code == code
        source
      end)
      |> expect(:config, fn :correct -> true end)

      capture_io(code, fn -> assert Runner.run(config) end)
    end

    test "does not run task with active: false", %{config: config} do
      TaskMock
      |> expect(:run, 2, fn source, config ->
        assert config == [autocorrect: true, foo: :bar]
        source
      end)
      |> expect(:config, 1, fn :correct -> true end)

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
      |> expect(:config, 1, fn :correct -> true end)

      config =
        Keyword.put(config, :tasks, [
          {TaskMock, exclude: "**/*.exs", config: [foo: :bar]}
        ])

      io =
        capture_io(fn ->
          assert Runner.run(config)
        end)

      # one dot per file
      assert io =~ ~r/\n\.\n/
    end

    test "runs task throwing exception", %{config: config} do
      TaskMock
      |> expect(:run, 2, fn _source, _config ->
        raise "ups"
      end)
      |> expect(:config, 1, fn :correct -> true end)

      config = Keyword.put(config, :tasks, [{TaskMock, []}])

      capture_io(fn ->
        assert project = Runner.run(config)
        assert [source, _rest] = Project.sources(project)
        assert [{1, issue}] = source.issues
        assert issue.reporter == Recode.Runner
      end)
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
  end
end
