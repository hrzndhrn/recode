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
        alias Foo.{Zumsel, Baz}

        def zoo, do: :zoo
      end
      """

      expected = """
      defmodule Mod do
        alias Foo.Zumsel
        alias Foo.Baz

        def zoo, do: :zoo
      end
      """

      source = run(code)

      assert_code source == expected
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

      assert_code source == expected
    end

    test "keeps the code as it is" do
      code = """
      defmodule Mod do
        alias Beta
        alias Alpha
      end
      """

      source = run(code)

      assert_code source == code
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
  end
end
