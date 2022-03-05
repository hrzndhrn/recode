defmodule Mix.Tasks.Recode.RenameTest do
  use RecodeCase

  import Mox

  alias Mix.Tasks.Recode.Rename, as: Task
  alias Recode.RunnerMock

  setup :verify_on_exit!

  test "mix recode.rename Rename.Bar.baz bar" do
    expect(RunnerMock, :run, fn {task, opts}, config ->
      assert task == Recode.Task.Rename
      assert opts == [from: {Rename.Bar, :baz, nil}, to: %{fun: :bar}]
      assert config == [inputs: "{lib,test}/**/*.{ex,exs}"]
    end)

    Task.run(["Rename.Bar.baz", "bar"])
  end
end
