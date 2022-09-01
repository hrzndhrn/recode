defmodule Mix.Tasks.Recode.RenameTest do
  use RecodeCase

  import Mox

  alias Mix.Tasks.Recode.Rename
  alias Recode.RunnerMock

  setup :verify_on_exit!

  test "mix recode.rename Rename.Bar.baz bar" do
    expect(RunnerMock, :run, fn {task, opts}, config ->
      assert task == Recode.Task.Rename
      assert opts == [config: [from: {Elixir.Rename.Bar, :baz, 5}, to: %{fun: :bar}]]
      assert config[:inputs] == ["{config,lib,test}/**/*.{ex,exs}"]
    end)

    Rename.run(["--config", "test/fixtures/rename/config.exs", "Rename.Bar.baz/5", "bar"])
  end

  test "mix recode.rename Rename.Bar.baz bar (other dir)" do
    dir = File.cwd!()
    File.cd!("test/fixtures/rename")

    expect(RunnerMock, :run, fn {task, opts}, config ->
      assert task == Recode.Task.Rename
      assert opts == [config: [from: {Elixir.Rename.Bar, :baz, 5}, to: %{fun: :bar}]]
      assert config[:inputs] == ["{config,lib,test}/**/*.{ex,exs}"]
    end)

    Rename.run(["--config", "../../../priv/config.exs", "Rename.Bar.baz/5", "bar"])

    File.cd!(dir)
  end

  test "mix recode.rename raises error for missing config" do
    assert_raise Mix.Error, "Config file not found", fn ->
      Rename.run(["--config", "../../../priv/no_configs.exs", "Rename.Bar.baz/5", "bar"])
    end
  end

  test "mix recode.rename raises error for invalid args" do
    assert_raise Mix.Error, "Can not parse arguments", fn -> Rename.run(["....", "bar"]) end
    assert_raise Mix.Error, "Can not parse arguments", fn -> Rename.run(["baz", "bar"]) end
    assert_raise Mix.Error, "Can not parse arguments", fn -> Rename.run(["Baz", "bar"]) end
  end

  test "mix recode.renam raises an error for missing args" do
    assert_raise Mix.Error, fn -> Rename.run([]) end
  end
end
