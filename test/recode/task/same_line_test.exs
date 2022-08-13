defmodule Recode.Task.SameLineTest do
  use RecodeCase

  alias Recode.Task.SameLine

  defp run(code) do
    code |> source() |> run_task({SameLine, []})
  end

  test "formats maps" do
    code = """
    %{
      foo: 42
    }
    """

    expected = """
    %{foo: 42}
    """

    %{
      foo: 42
    }

    source = run(code)

    assert formated?(code)
    assert source.code == expected
  end

  test "keeps format for single line map" do
    code = """
    %{foo: 42}
    """

    source = run(code)

    assert source.code == code
  end

  test "keeps format for a big map" do
    code = """
    %{
      foo: 42,
      foobar: 42,
      foobarbaz: 42,
      foobarbazbang: 42,
      foobarbazbangbuz: 42,
      foobarbazbangbuzwurz: 42,
      foobarbazbangbuzwurzumsel: 42
    }
    """

    source = run(code)

    assert formated?(code)
    assert source.code == code
  end

  test "formats list" do
    code = """
    [
      :a,
      :b,
      :c
    ]
    """

    expected = """
    [:a, :b, :c]
    """

    source = run(code)

    assert formated?(code)
    assert source.code == expected
  end

  test "formats multiline and" do
    code = """
    true and
      false and
      x
    """

    expected = """
    true and false and x
    """

    source = run(code)

    assert formated?(code)
    assert source.code == expected
  end

  test "formats multiline operators" do
    code = """
    1 +
      2 -
      3 /
        4 *
        5 +
      6
    """

    expected = """
    1 + 2 - 3 / 4 * 5 + 6
    """

    source = run(code)

    assert formated?(code)
    assert source.code == expected
  end

  test "formats def" do
    code = """
    def foo(
          x,
          y
        ) do
      {
        x,
        y
      }
    end
    """

    expected = """
    def foo(x, y) do
      {x, y}
    end
    """

    source = run(code)

    assert formated?(code)
    assert source.code == expected
  end

  test "formats defp with when" do
    code = """
    defp foo(x, y)
         when is_integer(x) do
      {x, y}
    end
    """

    expected = """
    defp foo(x, y) when is_integer(x) do
      {x, y}
    end
    """

    source = run(code)

    assert formated?(code)
    assert source.code == expected
  end

  test "formats def in module" do
    code = """
    defmodule MyCode.SameLine do
      def foo(x)
          when is_integer(x) do
        {
          :foo,
          x
        }
      end
    end
    """

    expected = """
    defmodule MyCode.SameLine do
      def foo(x) when is_integer(x) do
        {:foo, x}
      end
    end
    """

    source = run(code)

    assert formated?(code)
    assert source.code == expected
  end
end
