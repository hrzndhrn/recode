defmodule Recode.TaskTest do
  use ExUnit.Case

  alias Recode.Task

  defmodule Dummy do
    @shortdoc "Lorem ispum Dummy"

    use Recode.Task

    @impl true
    def run(source, _opts), do: source
  end

  defmodule CorrectorDummy do
    @shortdoc "Lorem ispum CorrectorDummy"

    use Recode.Task, corrector: true, checker: false, category: :test

    @impl true
    def run(source, _opts), do: source

    @impl true
    def init(config) do
      if Keyword.has_key?(config, :test) do
        {:ok, config}
      else
        {:error, "missing :test"}
      end
    end
  end

  test "corrector?/1" do
    assert Task.corrector?(Dummy) == false
    assert Task.corrector?(CorrectorDummy) == true
  end

  test "checker?/1" do
    assert Task.checker?(Dummy) == true
    assert Task.checker?(CorrectorDummy) == false
  end

  test "category/1" do
    assert Task.category(Dummy) == nil
    assert Task.category(CorrectorDummy) == :test
  end

  test "shortdoc/1" do
    assert Task.shortdoc(Dummy) == "Lorem ispum Dummy"
    assert Task.shortdoc(CorrectorDummy) == "Lorem ispum CorrectorDummy"
  end

  test "init/1" do
    assert Dummy.init(foo: :bar) == {:ok, foo: :bar}
    assert CorrectorDummy.init(foo: :bar) == {:error, "missing :test"}
    assert CorrectorDummy.init(test: :bar) == {:ok, test: :bar}
  end
end
