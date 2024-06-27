defmodule Recode.Task.ComparisonsTest do
  use RecodeCase

  alias Recode.Task.Comparisons

  describe "run/1" do
    test "equals" do
      code = """
      if foo == bar do
        true
      else
        false
      end
      """

      expected = """
      foo == bar
      """

      code
      |> run_task(Comparisons, autocorrect: true)
      |> assert_code(expected)
    end

    test "greater than" do
      code = """
      if foo > bar do
        true
      else
        false
      end
      """

      expected = """
      foo > bar
      """

      code
      |> run_task(Comparisons, autocorrect: true)
      |> assert_code(expected)
    end

    test "predicate" do
      code = """
      if foo?(bar) do
        true
      else
        false
      end
      """

      expected = """
      foo?(bar)
      """

      code
      |> run_task(Comparisons, autocorrect: true)
      |> assert_code(expected)
    end
  end
end
