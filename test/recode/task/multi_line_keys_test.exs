defmodule Recode.Task.MultiLineKeysTest do
  use RecodeCase

  alias Recode.Task.MultiLineKeys

  defp run(code, opts \\ []) do
    code |> source() |> run_task({MultiLineKeys, opts})
  end

  describe "keyword lists" do
    test "multilines" do
      code = """
      [name: "Watson", car: [maker: "Ford"], home: [city: "Porto Alegre", country: "Brazil"]]
      """

      expected = """
      [
        name: "Watson",
        car: [
          maker: "Ford"
        ],
        home: [
          city: "Porto Alegre",
          country: "Brazil"
        ]
      ]
      """

      assert run(code).code == expected
    end

    test "keyword list as function parameter" do
      code = """
      build_list(3, :person, name: "Watson", age: 12, state: "RS")
      """

      expected = """
      build_list(
        3,
        :person,
        name: "Watson",
        age: 12,
        state: "RS"
      )
      """

      assert run(code).code == expected
    end
  end

  describe "maps and structs" do
    test "multilines" do
      code = """
      %{name: "Watson", car: %{maker: "Ford"}, home: %Address{city: "Porto Alegre", country: "Brazil"}}
      """

      expected = """
      %{
        name: "Watson",
        car: %{maker: "Ford"},
        home: %Address{
          city: "Porto Alegre",
          country: "Brazil"
        }
      }
      """

      assert run(code).code == expected
    end

    test "does not update when single line map contains only one key" do
      code = """
      %{name: "Watson"}
      """

      expected = """
      %{name: "Watson"}
      """

      assert run(code).code == expected
    end

    test "does not update when map is already multilined" do
      code = """
      some_function = fn value ->
        %{
          name: "Watson",
          age: 90
        }
      end
      """

      expected = """
      some_function = fn value ->
        %{
          name: "Watson",
          age: 90
        }
      end
      """

      assert run(code).code == expected
    end
  end
end
