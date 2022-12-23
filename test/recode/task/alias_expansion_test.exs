defmodule Recode.Task.AliasExapnasionTest do
  use RecodeCase

  alias Recode.Task.AliasExpansion

  defp run(code, opts \\ [autocorrect: true]) do
    code |> source() |> run_task({AliasExpansion, opts})
  end

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

      source = run(code)

      assert_code(source == expected)
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

      source = run(code)

      assert_code(source == expected)
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

      source = run(code)

      assert_code(source == expected)
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

      source = run(code)

      assert_code(source == expected)
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

      source = run(code)

      assert_code(source == expected)
    end

    test "keeps the code as it is" do
      code = """
      defmodule Mod do
        alias Beta
        alias Alpha
      end
      """

      source = run(code)

      assert_code(source == code)
    end

    test "keeps the code as it is with __MODULE__" do
      code = """
      defmodule Mod do
        alias __MODULE__.Beta
        alias __MODULE__.Alpha.Delta
      end
      """

      source = run(code)

      assert_code(source == code)
    end

    test "reports no issues" do
      code = """
      defmodule Mod do
        alias Beta
        alias Alpha
      end
      """

      source = run(code, autocorrect: false)

      assert_no_issues(source)
    end

    test "reports an issue" do
      code = """
      defmodule Mod do
        alias Foo.{Beta, Alpha}
      end
      """

      source = run(code, autocorrect: false)

      assert_issue(source, AliasExpansion)
    end

    test "reports an issue for aliases with __MODULE__" do
      code = """
      defmodule Mod do
        alias __MODULE__.{Beta, Alpha}
      end
      """

      source = run(code, autocorrect: false)

      assert_issue(source, AliasExpansion)
    end
  end
end

{:__MODULE__, [trailing_comments: [], leading_comments: [], line: 2, column: 9], nil}
