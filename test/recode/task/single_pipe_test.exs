defmodule Recode.Task.SinglePipeTest do
  use RecodeCase

  alias Recode.Task.SinglePipe

  test "fixes single pipes" do
    source = """
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

    [updated] = run_task_with_sources({SinglePipe, []}, [source])

    assert updated == expected
  end

  test "keeps pipes" do
    source = """
    def ok(arg) do
      arg
      |> bar()
      |> baz(:baz)
    end
    """

    [updated] = run_task_with_sources({SinglePipe, []}, [source])

    assert updated == source
  end

  test "keeps pipes (length 3)" do
    source = """
    def ok(arg) do
      arg
      |> bar()
      |> baz(:baz)
      |> bing()
    end
    """

    [updated] = run_task_with_sources({SinglePipe, []}, [source])

    assert updated == source
  end

  test "keeps pipes with tap" do
    source = """
    def ok(arg) do
      arg
      |> bar()
      |> tap(fn x -> IO.inspect(x) end)
      |> baz(:baz)
    end
    """

    [updated] = run_task_with_sources({SinglePipe, []}, [source])

    assert updated == source
  end

  test "keeps pipes with then" do
    source = """
    def ok(arg) do
      arg
      |> bar()
      |> then(fn x -> IO.inspect(x) end)
    end
    """

    [updated] = run_task_with_sources({SinglePipe, []}, [source])

    assert updated == source
  end
end
