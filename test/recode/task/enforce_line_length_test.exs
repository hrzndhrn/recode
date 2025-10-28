defmodule Recode.Task.EnforceLineLengthTest do
  use RecodeCase

  alias Recode.Task.EnforceLineLength

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

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
  end

  test "keeps format for single line map" do
    """
    %{foo: 42}
    """
    |> run_task(EnforceLineLength, autocorrect: true)
    |> refute_update()
  end

  test "keeps format for a big map" do
    """
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
    |> run_task(EnforceLineLength, autocorrect: true)
    |> refute_update()
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

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
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

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
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

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
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

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
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

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
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

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
  end

  test "keeps with" do
    """
    with {:ok, a} <- foo(x),
         {:ok, b} <- bar(x) do
      {a, b}
    end
    """
    |> run_task(EnforceLineLength, autocorrect: true)
    |> refute_update()
  end

  test "formats with clauses" do
    code = """
    with {:ok, a} <-
           foo(x),
         {:ok, b} <-
           bar(x) do
      {a, b}
    end
    """

    expected = """
    with {:ok, a} <- foo(x),
         {:ok, b} <- bar(x) do
      {a, b}
    end
    """

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
  end

  test "keeps case" do
    """
    case x do
      :foo -> {:foo, x}
      :bar -> {:bar, x}
    end
    """
    |> run_task(EnforceLineLength, autocorrect: true)
    |> refute_update()
  end

  test "formats case clauses" do
    code = """
    case x do
      :foo ->
        {:foo, x}

      :bar ->
        {:bar, x}
    end
    """

    expected = """
    case x do
      :foo -> {:foo, x}
      :bar -> {:bar, x}
    end
    """

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
  end

  test "formats anonymous functions" do
    code = """
    fn x ->
      {:ok, x}
    end
    """

    expected = """
    fn x -> {:ok, x} end
    """

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
  end

  test "keeps fn with pattern matching" do
    ~S"""
    fn
      {:x, x} -> inspect("x = #{x}")
      {:y, y} -> inspect("y = #{y}")
    end
    """
    |> run_task(EnforceLineLength, autocorrect: true)
    |> refute_update()
  end

  test "formats fn without skip and ignore" do
    code = """
    fn
      x ->
        {
          :ok,
          x
        }
    end
    """

    expected = """
    fn x -> {:ok, x} end
    """

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
  end

  test "keeps fn with skip" do
    """
    fn
      x ->
        {
          :ok,
          x
        }
    end
    """
    |> run_task(EnforceLineLength, skip: [:fn])
    |> refute_update()
  end

  test "keeps fn with ignore" do
    code = """
    fn
      x ->
        {
          :ok,
          x
        }
    end
    """

    expected = """
    fn
      x -> {:ok, x}
    end
    """

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, ignore: [:fn], autocorrect: true)
    |> assert_code(expected)
  end

  test "inlines assert_raise" do
    code = """
    test "my test" do
      x = %{
        foo: :fail
      }

      assert_raise RuntimeError, fn ->
        do_some(%{
          x: x,
          y: :foo
        })
      end
    end
    """

    expected = """
    test "my test" do
      x = %{foo: :fail}

      assert_raise RuntimeError, fn -> do_some(%{x: x, y: :foo}) end
    end
    """

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
  end

  test "ignore fn" do
    code = """
    test "my test" do
      x = %{
        foo: :fail
      }

      assert_raise RuntimeError, fn ->
        do_some(%{
          x: x,
          y: :foo
        })
      end
    end
    """

    expected = """
    test "my test" do
      x = %{foo: :fail}

      assert_raise RuntimeError, fn ->
        do_some(%{x: x, y: :foo})
      end
    end
    """

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, ignore: [:fn], autocorrect: true)
    |> assert_code(expected)
  end

  test "skip assert_raise" do
    code = """
    test "my test" do
      x = %{
        foo: :fail
      }

      assert_raise RuntimeError, fn ->
        do_some(%{
          x: x,
          y: :foo
        })
      end
    end
    """

    expected = """
    test "my test" do
      x = %{foo: :fail}

      assert_raise RuntimeError, fn ->
        do_some(%{
          x: x,
          y: :foo
        })
      end
    end
    """

    assert formatted?(code)

    code
    |> run_task(EnforceLineLength, skip: [:assert_raise], autocorrect: true)
    |> assert_code(expected)
  end

  test "formats nested anonymous fn" do
    code = """
    defmodule TestModule do
      defp send_to_api(types, token) do
        types
        |> Enum.map(fn type ->
          Common.request(type, fn et ->
            ApiEstablishmentTypes.upsert(token, et)
          end)
        end)
      end
    end
    """

    expected = """
    defmodule TestModule do
      defp send_to_api(types, token) do
        types
        |> Enum.map(fn type ->
          Common.request(type, fn et -> ApiEstablishmentTypes.upsert(token, et) end)
        end)
      end
    end
    """

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
  end

  test "formats in keyword list" do
    code = """
    alias Recode.Task

    [
      verbose: false,
      inputs: ["{config,lib,test}/**/*.{ex,exs}"],
      formatter: {Recode.Formatter, []},
      tasks: [
        {Task.AliasOrder, []}
      ]
    ]
    """

    expected = """
    alias Recode.Task

    [
      verbose: false,
      inputs: ["{config,lib,test}/**/*.{ex,exs}"],
      formatter: {Recode.Formatter, []},
      tasks: [{Task.AliasOrder, []}]
    ]
    """

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(expected)
  end

  test "ignores inline do block" do
    code = """
    def foo,
      do: :foo
    """

    code
    |> run_task(EnforceLineLength, autocorrect: true)
    |> assert_code(code)
  end
end
