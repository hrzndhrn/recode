defmodule Recode.Task.RenameTest do
  use RecodeCase

  alias Recode.Task
  alias Rewrite.Project
  alias Rewrite.Source

  @path "test/fixtures/rename"
  @opts [from: {Rename.Bar, :baz, nil}, to: %{fun: :bar}]

  setup do
    on_exit(fn -> Code.put_compiler_option(:debug_info, true) end)
  end

  defp test_rename(file, opts) do
    path = Path.join([@path, "lib", file])
    config = [inputs: [path], dry: true]

    lib =
      {Task.Rename, config: opts}
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

  test "renames captures" do
    test_rename("capture.ex", @opts)
  end

  test "renames imported function" do
    test_rename("import.ex", @opts)
  end

  test "does not rename imported function" do
    test_rename("import_no_change.ex", @opts)
  end

  test "renames function with alias as" do
    test_rename("as.ex", @opts)
  end

  test "renames function aliased via use" do
    test_rename("use.ex", @opts)
  end

  test "renames function in 'setup do'" do
    test_rename("setup_do.exs", @opts)
  end

  test "renames function with arity" do
    opts = [from: {Rename.Bar, :baz, 1}, to: %{fun: :bar}]
    test_rename("with_arity.ex", opts)
  end

  test "does not renames function with missing debug info" do
    # The renaming fails just for functions calls that needs the debug info
    # to determine the full alias.
    Code.put_compiler_option(:debug_info, false)
    test_rename("no_debug_info.ex", @opts)
  end
end
