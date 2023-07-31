defmodule Mix.Tasks.Recode.Gen.HelpTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Mix.Tasks.Recode.Help

  test "mix recode.help" do
    output =
      capture_io(fn ->
        assert Help.run([]) == :ok
      end)

    assert output == """
           Readability tasks:
           AliasExpansion    # Exapnds multi aliases to separate aliases.
           AliasOrder        # Checks if aliases are sorted alphabetically.
           EnforceLineLength # Forces expressions to one line.
           Format            # Does the same as `mix format`.
           PipeFunOne        # Add parentheses to one-arity functions.
           SinglePipe        # Pipes should only be used when piping data through multiple calls.
           Specs             # Checks for specs.
           Refactor tasks:
           FilterCount       # Checks calls like Enum.filter(...) |> Enum.count().
           Nesting           # Checks code nesting depth in functions and macros.
           Warning tasks:
           Dbg               # There should be no calls to dbg.
           TestFileExt       # Checks the file extension of test files.
           UnusedVariable    # Checks if unused variables occur.
           """
  end

  test "mix recode.help Dbg" do
    output =
      capture_io(fn ->
        assert Help.run(["Dbg"]) == :ok
      end)

    assert output =~ "Recode.Task.Dbg"
  end

  test "mix recode.help FooBar" do
    assert_raise Mix.Error, "task FooBar not found", fn ->
      Help.run(["FooBar"])
    end
  end

  test "mix recode.help foo bar" do
    message = """
    recode.help does not support this command. \
    For more information run "mix help recode.help"\
    """

    assert_raise Mix.Error, message, fn ->
      Help.run(["foo", "bar"])
    end
  end
end
