defmodule Recode.Task.AliasExapnasionTest do
  use ExUnit.Case

  alias Recode.Task.PipeFunOne

  defp run(string) do
    string
    |> Sourceror.parse_string!()
    |> PipeFunOne.run()
  end

  describe "run/1" do
    test "expands aliases" do
      source = """
      def foo(arg) do
        arg
        |> bar
        |> baz(:baz)
        |> zoo()
      end
      """

      expected = """
      def foo(arg) do
        arg
        |> bar()
        |> baz(:baz)
        |> zoo()
      end\
      """

      assert source |> run() |> Sourceror.to_string() == expected
    end
  end
end
