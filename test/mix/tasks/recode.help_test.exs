defmodule Mix.Tasks.Recode.Gen.HelpTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Mix.Tasks.Recode.Help

  test "mix recode.help" do
    output =
      capture_io(fn ->
        assert Help.run([]) == :ok
      end)

    assert output =~ "Design tasks:"
    assert output =~ "Readability tasks:"
    assert output =~ "Refactor tasks:"
    assert output =~ "Warning tasks:"
    assert output =~ ~r/.*#.Checker\s*-/
    assert output =~ ~r/.*#.Corrector\s*-/
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
