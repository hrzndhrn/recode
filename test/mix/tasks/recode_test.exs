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
      ":test" |> source() |> project()
    end)

    capture_io(fn ->
      assert catch_exit(Tasks.Recode.run(["--config", "priv/config.exs"])) == :normal
    end)
  end

  test "mix recode --config priv/config.exs --dry" do
    expect(RunnerMock, :run, fn config ->
      assert Keyword.keyword?(config)
      assert config[:verbose] == true
      ":test" |> source() |> project()
    end)

    assert catch_exit(Tasks.Recode.run(["--config", "priv/config.exs", "--dry"])) == :normal
  end

  test "mix recode raises exception for unknown config file" do
    assert_raise Mix.Error, "Config file not found", fn ->
      Tasks.Recode.run(["--config", "priv/no_config.exs"])
    end
  end

  test "mix recode raises exception for unknown arg" do
    assert_raise Mix.Error, ~s|["inputs", "foo"] : Unknown|, fn ->
      Tasks.Recode.run(["--config", "priv/config.exs", "inputs", "foo"])
    end
  end

  test "mix recode raises exception for missing inputs" do
    assert_raise Mix.Error, "No sources found", fn ->
      Tasks.Recode.run(["--config", "priv/config.exs", "inputs"])
    end
  end
end
