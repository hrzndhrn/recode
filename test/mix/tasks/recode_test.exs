defmodule Mix.Tasks.RecodeTest do
  use RecodeCase

  import Mox

  alias Elixir.Recode.RunnerMock
  alias Mix.Tasks.Recode

  setup :verify_on_exit!

  test "mix recode --config priv/config.exs" do
    expect(RunnerMock, :run, fn tasks, config ->
      assert is_list(tasks)
      assert Keyword.keyword?(config)
    end)

    Recode.run(["--config", "priv/config.exs"])
  end

  test "mix recode --config priv/config.exs --dry" do
    expect(RunnerMock, :run, fn tasks, config ->
      assert is_list(tasks)
      assert Keyword.keyword?(config)
      assert config[:verbose] == true
    end)

    Recode.run(["--config", "priv/config.exs", "--dry"])
  end

  test "mix recode raises exception for unknown config file" do
    assert_raise Mix.Error, "Config file not found", fn -> Recode.run([]) end
  end

  test "mix recode raises exception for unknown arg" do
    assert_raise Mix.Error, ~s|["foo"] : Unknown|, fn -> Recode.run(["foo"]) end
  end
end
