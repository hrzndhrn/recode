defmodule Mix.Tasks.RecodeTest do
  use RecodeCase

  import ExUnit.CaptureIO
  import Mox

  alias Mix.Tasks
  alias Recode.RunnerMock

  setup :verify_on_exit!

  test "mix recode --config test/fixtures/config.exs" do
    expect(RunnerMock, :run, fn config ->
      assert Keyword.keyword?(config)
      assert config[:verbose] == false
      assert config[:manifest] == true
      {:ok, 0}
    end)

    capture_io(fn ->
      assert catch_exit(Tasks.Recode.run(["--config", "test/fixtures/config.exs"])) == :normal
    end)
  end

  test "mix recode --config test/fixtures/config.exs --dry" do
    expect(RunnerMock, :run, fn config ->
      assert Keyword.keyword?(config)
      assert config[:verbose] == true
      {:ok, 0}
    end)

    capture_io(fn ->
      assert catch_exit(Tasks.Recode.run(["--config", "test/fixtures/config.exs", "--dry"])) ==
               :normal
    end)
  end

  test "mix recode --config test/fixtures/config.exs -" do
    expect(RunnerMock, :run, fn config ->
      assert Keyword.keyword?(config)
      assert config[:inputs] == ["-"]
      {:ok, 0}
    end)

    capture_io(fn ->
      assert catch_exit(Tasks.Recode.run(["--config", "test/fixtures/config.exs", "-"])) ==
               :normal
    end)
  end

  test "mix recode file_1.ex file_2.ex" do
    expect(RunnerMock, :run, fn config ->
      assert Keyword.keyword?(config)
      assert config[:inputs] == ["file_1.ex", "file_2.ex"]
      {:ok, 0}
    end)

    capture_io(fn ->
      assert catch_exit(
               Tasks.Recode.run([
                 "--config",
                 "test/fixtures/config.exs",
                 "file_1.ex",
                 "file_2.ex"
               ])
             ) ==
               :normal
    end)
  end

  test "mix recode raises exception for unknown config file" do
    message = "Config file not found. Run `mix recode.gen.config` to create `.recode.exs`."

    assert_raise Mix.Error, message, fn ->
      Tasks.Recode.run(["--config", "priv/no_config.exs"])
    end
  end

  test "mix recode raises exception for unknown arg" do
    assert_raise OptionParser.ParseError, ~r|unknown-arg : Unknown option|, fn ->
      Tasks.Recode.run(["--config", "test/fixtures/config.exs", "--unknown-arg", "inputs", "foo"])
    end
  end

  test "mix recode raises exception for missing inputs" do
    message = "No sources found"

    assert_raise Mix.Error, message, fn ->
      Tasks.Recode.run(["--config", "test/fixtures/config.exs", "no-sources"])
    end
  end

  test "mix recode raises exception for an invalid task config" do
    message = """
    Invalid config keys [:invalid] for Recode.Task.Dbg found.
    Did you want to create a task-specific configuration:
    {Recode.Task.Dbg, [autocorrect: false, config: [invalid: :key]]}
    """

    assert_raise Mix.Error, message, fn ->
      Tasks.Recode.run(["--config", "test/fixtures/invalid_task_config.exs", "no-sources"])
    end
  end

  @tag :tmp_dir
  test "reads default config", context do
    expect(RunnerMock, :run, fn config ->
      assert Keyword.keyword?(config)
      assert config[:verbose] == false
      assert config[:debug] == false
      assert config[:manifest] == true

      {:ok, 0}
    end)

    in_tmp context do
      File.write!(".recode.exs", Recode.Config.to_string())
      assert catch_exit(Tasks.Recode.run([])) == :normal
    end
  end

  @tag :tmp_dir
  test "reads config", context do
    expect(RunnerMock, :run, fn config ->
      assert Keyword.keyword?(config)
      assert config[:verbose] == true
      assert config[:debug] == false
      assert config[:manifest] == false

      {:ok, 0}
    end)

    in_tmp context do
      config =
        Keyword.merge(Recode.Config.default(), verbose: true, manifest: false)

      File.write!(".recode.exs", Recode.Config.to_string(config))
      assert catch_exit(Tasks.Recode.run([])) == :normal
    end
  end

  @tag :tmp_dir
  test "overwrites manifest option", context do
    expect(RunnerMock, :run, fn config ->
      assert Keyword.keyword?(config)
      assert config[:manifest] == true

      {:ok, 0}
    end)

    in_tmp context do
      config = Keyword.merge(Recode.Config.default(), manifest: false)

      File.write!(".recode.exs", Recode.Config.to_string(config))
      assert catch_exit(Tasks.Recode.run(["--manifest"])) == :normal
    end
  end
end
