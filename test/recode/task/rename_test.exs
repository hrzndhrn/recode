defmodule Recode.Task.RenameTest do
  use RecodeCase

  alias Recode.Project
  alias Recode.Source
  alias Recode.Task

  # TODO: rename Rename.Bar to Fixture.Rename.Bar
  @path "test/fixtures/rename"
  @opts [from: {Rename.Bar, :baz, nil}, to: %{fun: :bar}]

  # mix rc.reanme --fun Rename.Bar.baz --to bar

  defp test_rename(file, opts) do
    path = Path.join([@path, "lib", file])
    config = [inputs: [path]]

    lib =
      {Task.Rename, opts}
      |> run_task(config)
      |> Project.source!(path)
      |> Source.code()

    exp = [@path, "exp", file] |> Path.join() |> File.read!()

    assert lib == exp
  end

  test "renames function calls" do
    test_rename("call.ex", @opts)
  end

  test "renames function definitions" do
    test_rename("definition.ex", @opts)
  end

  test "keeps function definitions in other modules" do
    test_rename("other_definition.ex", @opts)
  end

  test "renames imported function" do
    test_rename("import.ex", @opts)
  end

  test "renames function with alias as" do
    test_rename("as.ex", @opts)
  end
end
