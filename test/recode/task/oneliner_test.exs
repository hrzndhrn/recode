defmodule Recode.Task.SinglePipeTest do
  use RecodeCase

  alias Recode.Task.Oneliner

  defp run(code) do
    code |> source() |> run_task({Oneliner, []})
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

    source = run(code)

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

    assert source.code == expected
  end

  test "formats def" do

    code = """
    def foo(
      x,
      y
    ) do
      {x, y}
    end
    """

    expected = """
    def foo(x, y) do
      {x, y}
    end
    """

    source = run(code)

    assert source.code == expected
  end
end
