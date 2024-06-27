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

    test "keeps code as is" do
      code = """
      if foo?(bar) do
        false
      else
        true
      end
      """

      expected = """
      if foo?(bar) do
        false
      else
        true
      end
      """

      code
      |> run_task(Comparisons, autocorrect: true)
      |> assert_code(expected)
    end

    test "reports no issues" do
      """
      foo == bar
      """
      |> run_task(Comparisons, autocorrect: false)
      |> refute_issues()
    end

    test "reports an issue" do
      """
      if foo == bar do
        true
      else
        false
      end
      """
      |> run_task(Comparisons, autocorrect: false)
      |> assert_issue_with(reporter: Comparisons)
    end
  end
end
