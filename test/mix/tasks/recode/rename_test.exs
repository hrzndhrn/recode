defmodule Mix.Tasks.Recode.RenameTest do
  use RecodeCase

  import Mox

  alias Mix.Tasks.Recode.Rename
  alias Recode.RunnerMock

  setup :verify_on_exit!

  test "mix recode.rename Rename.Bar.baz bar" do
    expect(RunnerMock, :run, fn {task, opts}, config ->
      assert task == Recode.Task.Rename
      assert opts == [from: {Elixir.Rename.Bar, :baz, nil}, to: %{fun: :bar}]
      assert config == [inputs: "{lib,test}/**/*.{ex,exs}"]
    end)

    Rename.run(["Rename.Bar.baz", "bar"])
  end
end
