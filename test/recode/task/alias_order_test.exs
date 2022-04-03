defmodule Recode.Task.AliasOrderTest do
  use RecodeCase

  alias Recode.Task.AliasOrder

  defp run(code, opts \\ [autocorrect: true]) do
    code |> source() |> run_task({AliasOrder, opts})
  end

  test "keeps a sinlge alias" do
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

    assert source.code == expected
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

    assert source.code == expected
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

    assert source.code == expected
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

    assert source.code == expected
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

    assert source.code == expected
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

    assert source.code == expected
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
end
