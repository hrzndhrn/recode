defmodule Recode.Task.AliasOrderTest do
  use RecodeCase

  alias Rewrite.Source
  alias Recode.Task.AliasOrder
  alias Recode.Task.DirectiveOrder

  test "keeps a single alias" do
    """
    defmodule MyModule do
      alias Alpha
    end
    """
    |> run_task(AliasOrder, autocorrect: true)
    |> refute_update()
  end

  test "keeps sorted groups" do
    """
    defmodule MyModule do
      alias Yankee
      alias Zulu

      alias Alpha
      alias Bravo
    end
    """
    |> run_task(AliasOrder, autocorrect: true)
    |> refute_update()
  end

  test "sorts a group of aliases" do
    code = """
    defmodule MyModule do
      alias Zulu.Bravo
      alias Yankee.Alpha
      alias Alpha
      alias Delta
      alias Charlie
      alias Zulu.Alpha
      alias Bravo
    end
    """

    expected = """
    defmodule MyModule do
      alias Alpha
      alias Bravo
      alias Charlie
      alias Delta
      alias Yankee.Alpha
      alias Zulu.Alpha
      alias Zulu.Bravo
    end
    """

    code
    |> run_task(AliasOrder, autocorrect: true)
    |> assert_code(expected)
  end

  test "sorts __MODULE__" do
    code = """
    defmodule MyModule do
      alias Beta
      alias __MODULE__
      alias Alpha
    end
    """

    expected = """
    defmodule MyModule do
      alias Alpha
      alias Beta
      alias __MODULE__
    end
    """

    code
    |> run_task(AliasOrder, autocorrect: true)
    |> assert_code(expected)
  end

  test "sorts erlang modules" do
    code = """
    defmodule MyModule do
      alias :mnesia, as: Mnesia
      alias :ets, as: Ets
    end
    """

    expected = """
    defmodule MyModule do
      alias :ets, as: Ets
      alias :mnesia, as: Mnesia
    end
    """

    code
    |> run_task(AliasOrder, autocorrect: true)
    |> assert_code(expected)
  end

  test "sorts multi aliases" do
    code = """
    defmodule MyModule do
      alias Zulu.{Bravo, Echo.Foxtrot, Alpha}
      alias Delta
      def foo, do: :foo
    end
    """

    expected = """
    defmodule MyModule do
      alias Delta
      alias Zulu.{Alpha, Bravo, Echo.Foxtrot}

      def foo, do: :foo
    end
    """

    code
    |> run_task(AliasOrder, autocorrect: true)
    |> assert_code(expected)
  end

  test "ignores as for sorting" do
    code = """
    defmodule MyModule do
      alias Alpha, as: Zulu
      alias Bravo, as: Yankee

      def foo, do: :foo
    end
    """

    expected = """
    defmodule MyModule do
      alias Alpha, as: Zulu
      alias Bravo, as: Yankee

      def foo, do: :foo
    end
    """

    code
    |> run_task(AliasOrder, autocorrect: true)
    |> assert_code(expected)
  end

  test "put multi after single" do
    code = """
    defmodule MyModule do
      alias Alpha.{Bravo, Charlie}
      alias Alpha
    end
    """

    expected = """
    defmodule MyModule do
      alias Alpha
      alias Alpha.{Bravo, Charlie}
    end
    """

    code
    |> run_task(AliasOrder, autocorrect: true)
    |> assert_code(expected)
  end

  test "reports an issue" do
    """
    defmodule MyModule do
      alias Bravo
      alias Alpha
    end
    """
    |> run_task(AliasOrder, autocorrect: false)
    |> assert_issue_with(reporter: AliasOrder)
  end

  test "reports issues for unordered multiple groups" do
    """
    defmodule MyModule do
      alias Yankee.{Bravo, Alpha}
      alias Zulu.{Foxtrot, Echo}
    end
    """
    |> run_task(AliasOrder, autocorrect: false)
    |> assert_issues(2)
  end

  test "reports issues for unordered multiple groups with dots" do
    """
    defmodule MyModule do
      alias Yankee.{Bravo.Kilo, Alpha.Lima}
      alias Zulu.{Foxtrot, Echo}
    end
    """
    |> run_task(AliasOrder, autocorrect: false)
    |> assert_issues(2)
  end

  test "reports issues for unordered multiple groups with multi dots" do
    """
    defmodule MyModule do
      alias Whiskey.{Bravo.Charlie.Lima, Bravo.Charlie.Kilo}
      alias Yankee.{Bravo.Charlie.Lima, Bravo.Charlie}
      alias Zulu.{Bravo.Charlie, Bravo.Charlie.Lima}
    end
    """
    |> run_task(AliasOrder, autocorrect: false)
    |> assert_issues(2)
  end

  test "reports no issues" do
    """
    defmodule MyModule do
      alias Delta
      alias Yankee.{Alpha, Bravo}
      alias Zulu.{Echo, Foxtrot}

      alias Kilo
      alias Lima
    end
    """
    |> run_task(AliasOrder, autocorrect: false)
    |> refute_issues()
  end

  test "reports no issues for crazy groups" do
    """
    defmodule MyModule do
      alias Delta
      alias Yankee.{Alpha, Bravo}
      alias Zulu.{Echo, Foxtrot}
      use Foo
      alias Kilo
      alias Lima
    end
    """
    |> run_task(AliasOrder, autocorrect: false)
    |> refute_issues()
  end

  describe "Issue #52:" do
    test "reports an issue for unsorted aliases (case insensitive)" do
      """
      defmodule MyModule do
        alias App.Module.AnnotationV2
        alias App.Module.AnnotationsBehaviour
      end
      """
      |> run_task(AliasOrder, autocorrect: false)
      |> assert_issue()
    end

    test "reports an issue for unsorted aliases in multi (case insensitive)" do
      """
      defmodule MyModule do
        alias App.Module.{AnnotationV2, AnnotationsBehaviour}
      end
      """
      |> run_task(AliasOrder, autocorrect: false)
      |> assert_issue()
    end

    test "sort aliases (case insensitive)" do
      code = """
      defmodule MyModule do
        alias App.Module.AnnotationV2
        alias App.Module.AnnotationsBehaviour
      end
      """

      expected = """
      defmodule MyModule do
        alias App.Module.AnnotationsBehaviour
        alias App.Module.AnnotationV2
      end
      """

      code
      |> run_task(AliasOrder, autocorrect: true)
      |> assert_code(expected)
    end

    test "sort aliases in multi (case insensitive)" do
      code = """
      defmodule MyModule do
        alias App.Module.{AnnotationV2, AnnotationsBehaviour}
      end
      """

      expected = """
      defmodule MyModule do
        alias App.Module.{AnnotationV2, AnnotationsBehaviour}
      end
      """

      code
      |> run_task(AliasOrder, autocorrect: true)
      |> assert_code(expected)
    end
  end

  describe "Issue #51:" do
    test "reports an issue for unsorted aliases with __MODULE__" do
      """
      defmodule MyModule do
        alias __MODULE__.Beta
        alias __MODULE__.Alpha
      end
      """
      |> run_task(AliasOrder, autocorrect: false)
      |> assert_issue()
    end

    test "reports an issue for unsorted aliases in multi with __MODULE__" do
      """
      defmodule MyModule do
        alias __MODULE__.{Beta, Alpha}
      end
      """
      |> run_task(AliasOrder, autocorrect: false)
      |> assert_issue()
    end

    test "reports an issue for unsorted aliases in multi with and without __MODULE__" do
      """
      defmodule MyModule do
        alias Alpha.Bravo
        alias Alpha.Bravo.{Charlie, Delta}
        alias __MODULE__.{UserSocket, Endpoint}
      end
      """
      |> run_task(AliasOrder, autocorrect: false)
      |> assert_issue()
    end

    test "sorts aliases with __MODULE__" do
      code = """
      defmodule MyModule do
        alias __MODULE__.Beta
        alias __MODULE__.Alpha
      end
      """

      expected = """
      defmodule MyModule do
        alias __MODULE__.Alpha
        alias __MODULE__.Beta
      end
      """

      code
      |> run_task(AliasOrder, autocorrect: true)
      |> assert_code(expected)
    end

    test "sorts aliases in multi with __MODULE__" do
      code = """
      defmodule MyModule do
        alias __MODULE__.{Beta, Alpha}
      end
      """

      expected = """
      defmodule MyModule do
        alias __MODULE__.{Alpha, Beta}
      end
      """

      code
      |> run_task(AliasOrder, autocorrect: true)
      |> assert_code(expected)
    end
  end

  describe "issue #54" do
    test "ignores unquote in sorted aliases" do
      """
      defmodule RepoTestCase do
        defmacro __using__(opts) do
          repo = Keyword.fetch!(opts, :repo)

          quote do
            alias Foo.Bar
            alias unquote(repo), as: Repo
            alias Foo.Baz
          end
        end
      end
      """
      |> run_task(AliasOrder, autocorrect: false)
      |> refute_issues()
    end

    test "ignores unquote in unsorted aliases" do
      """
      defmodule RepoTestCase do
        defmacro __using__(opts) do
          repo = Keyword.fetch!(opts, :repo)

          quote do
            alias Foo.Baz
            alias unquote(repo), as: Repo
            alias Foo.Bar
          end
        end
      end
      """
      |> run_task(AliasOrder, autocorrect: false)
      |> assert_issue()
    end

    test "moves unquote to the top" do
      code = """
      defmodule RepoTestCase do
        defmacro __using__(opts) do
          repo = Keyword.fetch!(opts, :repo)

          quote do
            alias Foo.Bar
            alias unquote(repo), as: Repo
            alias Foo.Baz
          end
        end
      end
      """

      expected = """
      defmodule RepoTestCase do
        defmacro __using__(opts) do
          repo = Keyword.fetch!(opts, :repo)

          quote do
            alias unquote(repo), as: Repo
            alias Foo.Bar
            alias Foo.Baz
          end
        end
      end
      """

      code
      |> run_task(AliasOrder, autocorrect: true)
      |> assert_code(expected)
    end

    test "sorts aliases and moves unquote to the top" do
      code = """
      defmodule RepoTestCase do
        defmacro __using__(opts) do
          repo = Keyword.fetch!(opts, :repo)

          quote do
            alias Foo.Baz
            alias unquote(repo), as: Repo
            alias Foo.Bar
          end
        end
      end
      """

      expected = """
      defmodule RepoTestCase do
        defmacro __using__(opts) do
          repo = Keyword.fetch!(opts, :repo)

          quote do
            alias unquote(repo), as: Repo
            alias Foo.Bar
            alias Foo.Baz
          end
        end
      end
      """

      code
      |> run_task(AliasOrder, autocorrect: true)
      |> assert_code(expected)
    end
  end
end
