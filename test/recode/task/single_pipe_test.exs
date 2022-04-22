defmodule Recode.Task.SinglePipeTest do
  use RecodeCase

  alias Recode.Task.SinglePipe

  defp run(code, opts \\ [autocorrect: true]) do
    code |> source() |> run_task({SinglePipe, opts})
  end

  test "fixes single pipes" do
    code = """
    def fixme(arg) do
      arg |> zoo()
      arg |> zoo(:tiger)
    end
    """

    expected = """
    def fixme(arg) do
      zoo(arg)
      zoo(arg, :tiger)
    end
    """

    source = run(code)

    assert source.code == expected
  end

  test "expands single pipes" do
    code = """
    def fixme(arg) do
      foo(arg) |> bar()
      foo(arg, :animal) |> zoo(:tiger)
    end
    """

    expected = """
    def fixme(arg) do
      arg |> foo() |> bar()
      arg |> foo(:animal) |> zoo(:tiger)
    end
    """

    source = run(code)

    assert source.code == expected
  end

  test "keeps pipes" do
    code = """
    def ok(arg) do
      arg
      |> bar()
      |> baz(:baz)
    end
    """

    source = run(code)

    assert source.code == code
  end

  test "keeps pipes (length 3)" do
    code = """
    def ok(arg) do
      arg
      |> bar()
      |> baz(:baz)
      |> bing()
    end
    """

    source = run(code)

    assert source.code == code
  end

  test "keeps pipes with tap" do
    code = """
    def ok(arg) do
      arg
      |> bar()
      |> tap(fn x -> IO.puts(x) end)
      |> baz(:baz)
    end
    """

    source = run(code)

    assert source.code == code
  end

  test "keeps pipes with then" do
    code = """
    def ok(arg) do
      arg
      |> bar()
      |> then(fn x -> Enum.reverse(x) end)
    end
    """

    source = run(code)

    assert source.code == code
  end

  test "reports single pipes violation" do
    code = """
    def fixme(arg) do
      arg |> zoo()
      arg |> zoo(:tiger)
    end
    """

    source = run(code, autocorrect: false)

    assert_issues(source, SinglePipe, 2)
  end
end
