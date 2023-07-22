defmodule Recode.Task.AliasExapnasionTest do
  use RecodeCase

  alias Recode.Task.AliasExpansion

  describe "run/1" do
    test "expands aliases" do
      code = """
      defmodule Mod do
        alias Alpha.{Beta, Charlie}
        alias Delta.{Foxtrot, Golf}

        def foo, do: :foo
      end
      """

      expected = """
      defmodule Mod do
        alias Alpha.Beta
        alias Alpha.Charlie
        alias Delta.Foxtrot
        alias Delta.Golf

        def foo, do: :foo
      end
      """

      code
      |> run_task(AliasExpansion, autocorrect: true)
      |> assert_code(expected)
    end

    test "expands aliases keeps newline" do
      code = """
      defmodule Mod do
        alias Alpha.{Beta, Charlie}

        alias Delta.{Foxtrot, Golf}

        def foo, do: :foo
      end
      """

      expected = """
      defmodule Mod do
        alias Alpha.Beta
        alias Alpha.Charlie

        alias Delta.Foxtrot
        alias Delta.Golf

        def foo, do: :foo
      end
      """

      code
      |> run_task(AliasExpansion, autocorrect: true)
      |> assert_code(expected)
    end

    test "expands aliases with with comments" do
      code = """
      defmodule Mod do
        # a comment
        alias Bar
        alias Foo.{Zumsel, Baz}
        # another comment

        def zoo, do: :zoo
      end
      """

      expected = """
      defmodule Mod do
        # a comment
        alias Bar
        alias Foo.Zumsel
        alias Foo.Baz

        # another comment

        def zoo, do: :zoo
      end
      """

      code
      |> run_task(AliasExpansion, autocorrect: true)
      |> assert_code(expected)
    end

    test "expands long aliases" do
      code = """
      defmodule Mod do
        alias Alpha.Beta.Charlie.{Delta, Foxtrot, Foxtrot.Golf}

        def foo, do: :foo
      end
      """

      expected = """
      defmodule Mod do
        alias Alpha.Beta.Charlie.Delta
        alias Alpha.Beta.Charlie.Foxtrot
        alias Alpha.Beta.Charlie.Foxtrot.Golf

        def foo, do: :foo
      end
      """

      code
      |> run_task(AliasExpansion, autocorrect: true)
      |> assert_code(expected)
    end

    test "expands aliases with __MODULE__" do
      code = """
      defmodule Mod do
        alias __MODULE__.{Beta, Alpha}
        alias __MODULE__.Delta.{Foxtrot, Golf, Golf.Hotel}

        def foo, do: :foo
      end
      """

      expected = """
      defmodule Mod do
        alias __MODULE__.Beta
        alias __MODULE__.Alpha
        alias __MODULE__.Delta.Foxtrot
        alias __MODULE__.Delta.Golf
        alias __MODULE__.Delta.Golf.Hotel

        def foo, do: :foo
      end
      """

      code
      |> run_task(AliasExpansion, autocorrect: true)
      |> assert_code(expected)
    end

    test "keeps the code as it is" do
      """
      defmodule Mod do
        alias Beta
        alias Alpha
      end
      """
      |> run_task(AliasExpansion, autocorrect: true)
      |> refute_update()
    end

    test "keeps the code as it is with __MODULE__" do
      """
      defmodule Mod do
        alias __MODULE__.Beta
        alias __MODULE__.Alpha.Delta
      end
      """
      |> run_task(AliasExpansion, autocorrect: true)
      |> refute_update()
    end

    test "reports no issues" do
      """
      defmodule Mod do
        alias Beta
        alias Alpha
      end
      """
      |> run_task(AliasExpansion, autocorrect: false)
      |> refute_issues()
    end

    test "reports an issue" do
      """
      defmodule Mod do
        alias Foo.{Beta, Alpha}
      end
      """
      |> run_task(AliasExpansion, autocorrect: false)
      |> assert_issue_with(reporter: AliasExpansion)
    end

    test "reports an issue for aliases with __MODULE__" do
      """
      defmodule Mod do
        alias __MODULE__.{Beta, Alpha}
      end
      """
      |> run_task(AliasExpansion, autocorrect: false)
      |> assert_issue_with(reporter: AliasExpansion)
    end
  end
end
