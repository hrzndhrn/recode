defmodule Recode.Task.AliasExapnasionTest do
  use ExUnit.Case

  alias Recode.Task.AliasExpansion

  defp run(string) do
    string
    |> Sourceror.parse_string!()
    |> AliasExpansion.run()
  end

  describe "run/1" do
    test "expands aliases" do
      source = """
      defmodule Mod do
        alias Foo.{Zumsel, Baz}

        def zoo, do: :zoo
      end
      """

      expected = """
      defmodule Mod do
        alias Foo.Zumsel
        alias Foo.Baz

        def zoo, do: :zoo
      end\
      """

      assert source |> run() |> Sourceror.to_string() == expected
    end
  end
end
