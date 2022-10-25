defmodule Recode.Task.KeysOrderTest do
  use RecodeCase

  alias Recode.Task.KeysOrder

  defp run(code, opts \\ []) do
    code |> source() |> run_task({KeysOrder, opts})
  end

  test "orders struct keys" do
    code = """
    %Person{
      name: "John Titor",
      company: "IBM"
    }
    """

    expected = """
    %Person{
      company: "IBM",
      name: "John Titor"
    }
    """

    assert run(code).code == expected
  end

  test "orders map keys" do
    code = """
    %{
      name: "John Titor",
      company: "IBM",
      car: %{
        year: 2022,
        maker: "Ford"
      }
    }
    """

    expected = """
    %{
      car: %{
        maker: "Ford",
        year: 2022
      },
      company: "IBM",
      name: "John Titor"
    }
    """

    assert run(code).code == expected
  end

  test "orders keyword list keys" do
    code = """
    [
      name: "John Titor",
      company: "IBM"
    ]
    """

    expected = """
    [
      company: "IBM",
      name: "John Titor"
    ]
    """

    assert run(code).code == expected
  end

  test "orders keyword list keys inside function calls" do
    code = """
    build(:person, name: "John Titor", company: "IBM")
    """

    expected = """
    build(:person, company: "IBM", name: "John Titor")
    """

    assert run(code).code == expected
  end

  test "does not order a regular list" do
    code = """
    [:person, :name]
    """

    expected = """
    [:person, :name]
    """

    assert run(code).code == expected
  end
end
