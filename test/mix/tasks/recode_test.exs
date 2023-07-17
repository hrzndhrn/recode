defmodule Mix.Tasks.RecodeTest do
  use RecodeCase

  import ExUnit.CaptureIO
  import Mox

  alias Mix.Tasks
  alias Recode.RunnerMock

  setup :verify_on_exit!

  test "mix recode --config priv/config.exs" do
    expect(RunnerMock, :run, fn config ->
      assert Keyword.keyword?(config)
      ":test" |> source("test.exs") |> project()
    end)

    capture_io(fn ->
      assert catch_exit(Tasks.Recode.run(["--config", "priv/config.exs"])) == :normal
    end)
  end

  test "mix recode --config priv/config.exs --dry" do
    expect(RunnerMock, :run, fn config ->
      assert Keyword.keyword?(config)
      assert config[:verbose] == true
      ":test" |> source("test.exs") |> project()
    end)

    assert catch_exit(Tasks.Recode.run(["--config", "priv/config.exs", "--dry"])) == :normal
  end

  test "mix recode --config priv/config.exs -" do
    expect(RunnerMock, :run, fn config ->
      assert Keyword.keyword?(config)
      assert config[:inputs] == ["-"]

      ":test" |> source("test.exs") |> project()
    end)

    assert catch_exit(Tasks.Recode.run(["--config", "priv/config.exs", "-"])) == :normal
  end

  test "mix recode file_1.ex file_2.ex" do
    expect(RunnerMock, :run, fn config ->
      assert Keyword.keyword?(config)
      assert config[:inputs] == ["file_1.ex", "file_2.ex"]

      ":test" |> source("test.exs") |> project()
    end)

    assert catch_exit(Tasks.Recode.run(["--config", "priv/config.exs", "file_1.ex", "file_2.ex"])) ==
             :normal
  end

  test "mix recode raises exception for unknown config file" do
    message = "Config file not found. Run `mix recode.gen.config` to create `.recode.exs`."

    assert_raise Mix.Error, message, fn ->
      Tasks.Recode.run(["--config", "priv/no_config.exs"])
    end
  end

  test "mix recode raises exception for unknown arg" do
    assert_raise OptionParser.ParseError, ~r|unknown-arg : Unknown option|, fn ->
      Tasks.Recode.run(["--config", "priv/config.exs", "--unknown-arg", "inputs", "foo"])
    end
  end

  test "mix recode raises exception for missing inputs" do
    assert_raise Mix.Error, "No sources found", fn ->
      Tasks.Recode.run(["--config", "priv/config.exs", "no-sources"])
    end
  end
end
