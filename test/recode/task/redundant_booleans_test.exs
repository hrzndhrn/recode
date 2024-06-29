defmodule Recode.Task.RedundantBooleansTest do
  use RecodeCase

  alias Recode.Task.RedundantBooleans

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
      |> run_task(RedundantBooleans, autocorrect: true)
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
      |> run_task(RedundantBooleans, autocorrect: true)
      |> assert_code(expected)
    end

    test "keyword syntax" do
      code = """
      if foo?(bar), do: true, else: false
      """

      expected = """
      foo?(bar)
      """

      code
      |> run_task(RedundantBooleans, autocorrect: true)
      |> assert_code(expected)
    end

    test "negates code with reverse booleans" do
      code = """
      if some_call?() && (some_other_call?() || another_call?()) do
        false
      else
        true
      end
      """

      expected = """
      not (some_call?() && (some_other_call?() || another_call?()))
      """

      code
      |> run_task(RedundantBooleans, autocorrect: true)
      |> assert_code(expected)
    end

    test "maintains leading comments" do
      code = """
      # I'm a comment
      if foo?(bar) do
        true
      else
        false
      end
      """

      expected = """
      # I'm a comment
      foo?(bar)
      """

      code
      |> run_task(RedundantBooleans, autocorrect: true)
      |> assert_code(expected)
    end

    test "keeps code as is without booleans" do
      code = """
      if foo?(bar) do
        bar
      else
        false
      end
      """

      expected = """
      if foo?(bar) do
        bar
      else
        false
      end
      """

      code
      |> run_task(RedundantBooleans, autocorrect: true)
      |> assert_code(expected)
    end

    test "reports no issues" do
      """
      foo == bar
      """
      |> run_task(RedundantBooleans, autocorrect: false)
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
      |> run_task(RedundantBooleans, autocorrect: false)
      |> assert_issue_with(reporter: RedundantBooleans)
    end
  end
end
