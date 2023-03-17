defmodule Recode.Task.AliasOrderTest do
  use RecodeCase

  alias Recode.Task.AliasOrder

  defp run(code, opts \\ [autocorrect: true]) do
    code |> source() |> run_task({AliasOrder, opts})
  end

  test "keeps a single alias" do
    code = """
    defmodule MyModule do
      alias Alpha
    end
    """

    expected = """
    defmodule MyModule do
      alias Alpha
    end
    """

    source = run(code)

    assert_code source == expected
  end

  test "keeps sorted groups" do
    code = """
    defmodule MyModule do
      alias Yankee
      alias Zulu

      alias Alpha
      alias Bravo
    end
    """

    expected = """
    defmodule MyModule do
      alias Yankee
      alias Zulu

      alias Alpha
      alias Bravo
    end
    """

    source = run(code)

    assert_code source == expected
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

    source = run(code)

    assert_code source == expected
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

    source = run(code)

    assert_code source == expected
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

    source = run(code)

    assert_code source == expected
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

    source = run(code)

    assert_code source == expected
  end

  test "reports an issue" do
    code = """
    defmodule MyModule do
      alias Bravo
      alias Alpha
    end
    """

    source = run(code, autocorrect: false)

    assert_issues(source, AliasOrder, 1)
  end

  test "reports issues for unordered multiple groups" do
    code = """
    defmodule MyModule do
      alias Yankee.{Bravo, Alpha}
      alias Zulu.{Foxtrot, Echo}
    end
    """

    source = run(code, autocorrect: false)

    assert_issues(source, AliasOrder, 2)
  end

  test "reports no issues" do
    code = """
    defmodule MyModule do
      alias Delta
      alias Yankee.{Alpha, Bravo}
      alias Zulu.{Echo, Foxtrot}

      alias Kilo
      alias Lima
    end
    """

    source = run(code, autocorrect: false)

    assert_no_issues(source)
  end

  test "reports no issues for crazy groups" do
    code = """
    defmodule MyModule do
      alias Delta
      alias Yankee.{Alpha, Bravo}
      alias Zulu.{Echo, Foxtrot}
      use Foo
      alias Kilo
      alias Lima
    end
    """

    source = run(code, autocorrect: false)

    assert_no_issues(source)
  end

  describe "Issue #52:" do
    test "reports an issue for unsorted aliases (case insensitive)" do
      code = """
      defmodule MyModule do
        alias App.Module.AnnotationV2
        alias App.Module.AnnotationsBehaviour
      end
      """

      source = run(code, autocorrect: false)

      assert_issues(source, AliasOrder, 1)
    end

    test "reports an issue for unsorted aliases in multi (case insensitive)" do
      code = """
      defmodule MyModule do
        alias App.Module.{AnnotationV2, AnnotationsBehaviour}
      end
      """

      source = run(code, autocorrect: false)

      assert_issues(source, AliasOrder, 1)
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

      source = run(code)

      assert_code source == expected
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

      source = run(code)

      assert_code source == expected
    end
  end

  describe "Issue #51:" do
    test "reports an issue for unsorted aliases with __MODULE__" do
      code = """
      defmodule MyModule do
        alias __MODULE__.Beta
        alias __MODULE__.Alpha
      end
      """

      source = run(code, autocorrect: false)

      assert_issues(source, AliasOrder, 1)
    end

    test "reports an issue for unsorted aliases in multi with __MODULE__" do
      code = """
      defmodule MyModule do
        alias __MODULE__.{Beta, Alpha}
      end
      """

      source = run(code, autocorrect: false)

      assert_issues(source, AliasOrder, 1)
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

      source = run(code)

      assert_code source == expected
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

      source = run(code)

      assert_code source == expected
    end
  end

  describe "issue #54" do
    test "ignores unquote in sorted aliases" do
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

      source = run(code, autocorrect: false)

      assert_no_issues(source)
    end

    test "ignores unquote in unsorted aliases" do
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

      source = run(code, autocorrect: false)

      assert_issues(source, AliasOrder, 1)
    end

    test "moves unquote to the top" do
      code = """
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

      source = run(code, autocorrect: true)

      assert_code source == code
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

      source = run(code, autocorrect: true)

      assert_code source == expected
    end
  end
end
