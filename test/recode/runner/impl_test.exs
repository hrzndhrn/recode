defmodule Recode.Runner.ImplTest do
  use ExUnit.Case

  alias Recode.Project
  alias Recode.Runner.Impl, as: Runner
  alias Recode.Task.SinglePipe

  setup_all context do
    cwd = File.cwd!()
    File.cd!("test/fixtures/runner")

    config = "config.exs" |> Code.eval_file() |> elem(0)

    on_exit(fn -> File.cd(cwd) end)

    Map.put(context, :config, config)
  end

  describe "run/1" do
    test "runs tasks from config", %{config: config} do
      config = Keyword.merge(config, dry: true, tasks: [{SinglePipe, []}])

      assert %Project{} = Runner.run(config)
    end

    test "runs tasks from config (autocorrect: false)", %{config: config} do
      config = Keyword.merge(config, dry: true, autocorrect: false, tasks: [{SinglePipe, []}])

      assert %Project{} = Runner.run(config)
    end
  end

  describe "run/2" do
    test "runs one task", %{config: config} do
      assert %Project{} = Runner.run({SinglePipe, []}, config)
    end

    test "runs two tasks", %{config: config} do
      assert %Project{} = Runner.run([{SinglePipe, []}, {SinglePipe, []}], config)
    end
  end
end
