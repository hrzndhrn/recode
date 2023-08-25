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
           Design tasks:
           TagFIXME          # Checker   - Checks if there are FIXME tags in the sources.
           TagTODO           # Checker   - Checks if there are TODO tags in the sources.
           Readability tasks:
           AliasExpansion    # Corrector - Exapnds multi aliases to separate aliases.
           AliasOrder        # Corrector - Checks if aliases are sorted alphabetically.
           EnforceLineLength # Corrector - Forces expressions to one line.
           Format            # Corrector - Does the same as `mix format`.
           PipeFunOne        # Corrector - Add parentheses to one-arity functions.
           SinglePipe        # Corrector - Pipes should only be used when piping data through multiple calls.
           Specs             # Checker   - Checks for specs.
           Refactor tasks:
           FilterCount       # Corrector - Checks calls like Enum.filter(...) |> Enum.count().
           Nesting           # Checker   - Checks code nesting depth in functions and macros.
           Warning tasks:
           Dbg               # Corrector - There should be no calls to dbg.
           IOInspect         # Corrector - There should be no calls to IO.inspect.
           TestFileExt       # Corrector - Checks the file extension of test files.
           UnusedVariable    # Corrector - Checks if unused variables occur.
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
    message = """
    The recode task FooBar could not be found. Run "mix recode.help" for a list of recode tasks.\
    """

    assert_raise Mix.Error, message, fn ->
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
